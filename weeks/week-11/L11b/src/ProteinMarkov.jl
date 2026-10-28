# =============================================================================
# CHEME 5800 | L11b supplied code: the position-aware protein generator
# =============================================================================
# This file is complete; your work for this meeting is in Compute.jl. It backs
# the protein-generator example and holds four groups of functions:
#
#   1. READING    read_fasta, standard_alignment      the alignment on disk
#   2. ENCODING   onehot_matrix                       the alignment as a matrix
#   3. MODEL      fit_position_aware_markov,          fit it, then sample from it
#                 sample_sequences, draw_index
#   4. METRICS    amino_acid_composition, kl_divergence, sequence_identity,
#                 mean_nearest_identity, pairwise_diversity, conserved_positions,
#                 position_frequency, scaffold_retention
#
# Every sequence here is a String over the 20 standard amino acids, every
# alignment position is counted from 1, and every function that draws random
# numbers takes a `seed` and builds its own generator, so nothing in this file
# disturbs Julia's global random state.
#
# Include.jl loads this file on every run, so edits are picked up by re-running
# the setup cell at the top of the notebook.
# =============================================================================
module L11bProteinMarkov

import Random

export AMINO_ACIDS,
    PositionAwareMarkovModel,
    amino_acid_composition,
    conserved_positions,
    fit_position_aware_markov,
    kl_divergence,
    mean_nearest_identity,
    onehot_matrix,
    pairwise_diversity,
    position_frequency,
    read_fasta,
    sample_sequences,
    scaffold_retention,
    sequence_identity,
    standard_alignment

"""
    AMINO_ACIDS

The 20 standard amino acids as one-letter symbols, in alphabetical order. This order
fixes the meaning of every index in this file: row `i` of a transition matrix, entry
`i` of a composition vector, and column block `i` of a one-hot row all refer to
`AMINO_ACIDS[i]`. Anything outside this set, including an alignment gap, is rejected.
"""
const AMINO_ACIDS = collect("ACDEFGHIKLMNPQRSTVWY")

"""
    PositionAwareMarkovModel

Hold a first-order Markov model for an aligned protein family. The model uses one
initial amino-acid distribution and one transition matrix for each adjacent pair
of alignment positions. `transition_probabilities[ℓ, i, j]` is the probability
of amino acid `alphabet[j]` at position `ℓ + 1`, conditional on amino acid
`alphabet[i]` at position `ℓ`.

### Fields
- `alphabet::Vector{Char}`: the symbols the model can emit, in index order.
- `initial_probabilities::Vector{Float64}`: the distribution over the first position;
  sums to one.
- `transition_probabilities::Array{Float64,3}`: `(L-1)` by `q` by `q`, one `q` by `q`
  matrix per adjacent pair of positions. Row `[ℓ, i, :]` sums to one when the family
  shows `alphabet[i]` at position `ℓ`, and is all zeros when it never does.
- `sequence_length::Int`: `L`, the aligned length every sampled sequence will have.
"""
struct PositionAwareMarkovModel
    alphabet::Vector{Char}
    initial_probabilities::Vector{Float64}
    transition_probabilities::Array{Float64,3}
    sequence_length::Int
end

"""
    read_fasta(path::AbstractString) -> Vector{NamedTuple}

Read a FASTA file and return records with `id::String` and `sequence::String`
fields. Sequence lines belonging to the same record are concatenated. Empty
records and sequence data before the first header are rejected.

A FASTA file holds a header line beginning with `>`, then one or more lines of
sequence, repeated for every record. Sequence lines are often wrapped at a fixed
width, which is why the parts are joined before a record is stored.

### Arguments
- `path::AbstractString`: the FASTA file to read.

### Returns
- `Vector{NamedTuple}`: one `(id = ..., sequence = ...)` per record, in file order.
  Sequences are upper-cased; no alphabet filtering happens here.

### Errors
Throws an `ArgumentError` for a header with no identifier, a record with no sequence,
sequence data before the first header, or a file with no records at all.
"""
function read_fasta(path::AbstractString)::Vector{NamedTuple{(:id, :sequence),Tuple{String,String}}}
    records = NamedTuple{(:id, :sequence),Tuple{String,String}}[]
    identifier = nothing
    sequence_parts = String[]

    # walk the file one line at a time, finishing a record whenever a new header starts -
    for raw_line in eachline(path)
        line = strip(raw_line) # drop surrounding whitespace, including the line ending
        isempty(line) && continue # blank lines carry no information

        if startswith(line, ">") # a header closes the record before it, if there was one
            if !isnothing(identifier)
                sequence = join(sequence_parts)
                isempty(sequence) && throw(ArgumentError("FASTA record $(identifier) has no sequence."))
                push!(records, (id = identifier, sequence = sequence))
            end
            identifier = strip(line[2:end]) # everything after the '>' names the record
            isempty(identifier) && throw(ArgumentError("FASTA headers must contain an identifier."))
            empty!(sequence_parts)
        else
            isnothing(identifier) && throw(ArgumentError("FASTA sequence data appeared before the first header."))
            push!(sequence_parts, uppercase(line)) # a wrapped sequence arrives over several lines
        end
    end

    # the final record has no header after it to trigger the push above -
    if !isnothing(identifier)
        sequence = join(sequence_parts)
        isempty(sequence) && throw(ArgumentError("FASTA record $(identifier) has no sequence."))
        push!(records, (id = identifier, sequence = sequence))
    end

    isempty(records) && throw(ArgumentError("The FASTA file contains no records."))
    return records
end

"""
    standard_alignment(records; alphabet=AMINO_ACIDS) -> Vector{String}

Return the aligned sequences that contain only characters in the supplied amino-
acid alphabet. All retained sequences must have the same length. Records containing
alignment gaps or non-standard amino-acid symbols are excluded.

Note what is and is not a filter here. Records are dropped only for their symbols; the
equal-length requirement is checked against whatever survives and raises an error rather
than discarding anything. In an aligned file every record already shares one length, so
in practice the alphabet test is what removes records.

### Arguments
- `records::AbstractVector`: records carrying a `sequence` field, as `read_fasta` returns.
- `alphabet::AbstractVector{Char}`: the symbols a kept sequence may use.

### Returns
- `Vector{String}`: the kept sequences, in input order.

### Errors
Throws an `ArgumentError` if no record uses only `alphabet`, or if the kept sequences do
not all share one length.
"""
function standard_alignment(records::AbstractVector; alphabet::AbstractVector{Char} = AMINO_ACIDS)::Vector{String}
    allowed = Set(alphabet) # a Set makes the per-character membership test fast
    # keep a record only if every one of its characters is in the alphabet -
    sequences = [record.sequence for record in records if all(character -> character ∈ allowed, record.sequence)]
    isempty(sequences) && throw(ArgumentError("No sequences use only the supplied amino-acid alphabet."))

    sequence_length = length(first(sequences))
    all(length(sequence) == sequence_length for sequence in sequences) ||
        throw(ArgumentError("The retained protein sequences must have the same aligned length."))
    return sequences
end

"""
    onehot_matrix(sequences::AbstractVector{<:AbstractString};
        alphabet::AbstractVector{Char} = AMINO_ACIDS) -> Array{Float64,2}

Encode aligned protein sequences as a numerical data matrix, one row per sequence.

Each sequence of length `L` becomes an `L` by `q` block of indicator values, where `q` is the
size of the alphabet: the entry for the amino acid present at a position is `1.0`, and the
other `q - 1` entries at that position are `0.0`. Reading the block one position at a time
gives a row of length `L*q`, so column `(ℓ - 1)*q + i` carries alphabet symbol `i` at alignment
position `ℓ`. Every row has exactly `L` nonzero entries, and the mean of a column is the family
frequency of that amino acid at that position.

### Arguments
- `sequences::AbstractVector{<:AbstractString}`: equal-length aligned sequences written in
  `alphabet`.
- `alphabet::AbstractVector{Char}`: the symbols to encode, in the column order described above.
  Defaults to the 20 standard amino acids.

### Returns
- `Array{Float64,2}`: an `n` by `L*q` matrix, where `n` is the number of sequences.

### Errors
Throws an `ArgumentError` if `sequences` is empty, if the sequences differ in length, or if a
sequence contains a symbol outside `alphabet`.

### Example
```julia
X = onehot_matrix(["AC", "AD"]); # 2 by 40: two sequences, two positions, 20 symbols each
sum(X, dims = 2) # every row sums to 2, the number of alignment positions
```
"""
function onehot_matrix(sequences::AbstractVector{<:AbstractString};
    alphabet::AbstractVector{Char} = AMINO_ACIDS)::Array{Float64,2}

    isempty(sequences) && throw(ArgumentError("At least one sequence is required."))
    sequence_length = length(first(sequences))
    all(length(sequence) == sequence_length for sequence ∈ sequences) ||
        throw(ArgumentError("Sequences must have equal length."))

    state_index = Dict(character => index for (index, character) ∈ enumerate(alphabet))
    number_of_states = length(alphabet)
    X = zeros(Float64, length(sequences), sequence_length * number_of_states)

    # one row per sequence: write a 1.0 in the column of the amino acid seen at each position -
    for (row, sequence) ∈ enumerate(sequences)
        for (position, character) ∈ enumerate(sequence)
            index = get(state_index, character, nothing)
            isnothing(index) &&
                throw(ArgumentError("Sequence contains a character outside the alphabet."))
            X[row, (position - 1)*number_of_states + index] = 1.0
        end
    end
    return X
end

"""
    fit_position_aware_markov(sequences; alphabet=AMINO_ACIDS, weights=ones(...))
        -> PositionAwareMarkovModel

Estimate a position-aware first-order Markov model from equal-length aligned protein
sequences. `weights[k]` is the non-negative relative count assigned to sequence `k`;
uniform weights recover ordinary empirical frequencies. Every observed transition
row is normalized to sum to one. The sequences must contain only `alphabet` symbols.

A row is left as all zeros when its amino acid never appears at that position in the
family, since there is no evidence to normalize. `sample_sequences` can never select
such a row: it only moves to an amino acid through a transition with a positive count,
and that same count makes the next row nonzero.

### Arguments
- `sequences::AbstractVector{<:AbstractString}`: equal-length aligned sequences,
  at least two positions long.
- `alphabet::AbstractVector{Char}`: the symbols the model may emit.
- `weights::AbstractVector{<:Real}`: one non-negative weight per sequence. A weight is a
  relative count, so doubling every weight changes nothing, while doubling one sequence's
  weight counts it twice.

### Returns
- `PositionAwareMarkovModel`: the fitted model.

### Errors
Throws an `ArgumentError` for empty input, a weight that is negative or not finite, all-zero
weights, a wrong number of weights, sequences shorter than two positions or of unequal
length, or a character outside `alphabet`.
"""
function fit_position_aware_markov(
    sequences::AbstractVector{<:AbstractString};
    alphabet::AbstractVector{Char} = AMINO_ACIDS,
    weights::AbstractVector{<:Real} = ones(length(sequences)),
)::PositionAwareMarkovModel

    isempty(sequences) && throw(ArgumentError("At least one protein sequence is required."))
    length(weights) == length(sequences) || throw(ArgumentError("Supply one weight per sequence."))
    all(isfinite(weight) && weight ≥ 0 for weight in weights) ||
        throw(ArgumentError("Sequence weights must be finite and non-negative."))
    sum(weights) > 0 || throw(ArgumentError("At least one sequence weight must be positive."))

    sequence_length = length(first(sequences))
    sequence_length ≥ 2 || throw(ArgumentError("Protein sequences must contain at least two positions."))
    all(length(sequence) == sequence_length for sequence in sequences) ||
        throw(ArgumentError("Protein sequences must have the same aligned length."))

    states = collect(alphabet)
    state_index = Dict(character => index for (index, character) ∈ enumerate(states))
    all(all(haskey(state_index, character) for character ∈ sequence) for sequence ∈ sequences) ||
        throw(ArgumentError("Every sequence character must belong to the supplied alphabet."))

    # counts, not probabilities, until the normalizing loop below -
    number_of_states = length(states)
    initial_counts = zeros(Float64, number_of_states)
    transition_counts = zeros(Float64, sequence_length - 1, number_of_states, number_of_states)

    # tally every sequence, adding its weight rather than 1 to each count it contributes -
    for (sequence, weight) ∈ zip(sequences, weights)
        characters = collect(sequence) # a Vector{Char}, so positions index directly
        initial_counts[state_index[characters[1]]] += weight # the first position feeds the initial distribution
        for position ∈ 1:(sequence_length - 1) # each adjacent pair feeds one transition matrix
            current_index = state_index[characters[position]]
            next_index = state_index[characters[position + 1]]
            transition_counts[position, current_index, next_index] += weight
        end
    end

    # turn counts into probabilities: the initial vector, then one transition row at a time -
    initial_probabilities = initial_counts ./ sum(initial_counts)
    transition_probabilities = zeros(Float64, size(transition_counts))
    for position ∈ 1:(sequence_length - 1), current_index ∈ 1:number_of_states
        row_total = sum(transition_counts[position, current_index, :]) # total weight leaving this state
        if row_total > 0 # an unobserved state has no evidence, so its row stays all zeros
            transition_probabilities[position, current_index, :] =
                transition_counts[position, current_index, :] ./ row_total
        end
    end

    return PositionAwareMarkovModel(
        states,
        initial_probabilities,
        transition_probabilities,
        sequence_length,
    )
end

"""
    draw_index(probabilities::AbstractVector{<:Real}, rng) -> Int

Draw one index at random, with probability proportional to `probabilities[index]`.

This is inverse-transform sampling. Picture the entries laid end to end as segments of a
line of length `total`. Dropping a uniform point on that line lands inside exactly one
segment, and a longer segment catches the point more often, which is what "proportional"
means. Walking the running total and stopping at the first index that reaches the point
finds that segment.

The weights need not sum to one, since the draw is scaled by their total. This function is
internal to the module and is not exported.

### Arguments
- `probabilities::AbstractVector{<:Real}`: non-negative weights, at least one positive.
- `rng`: the random number generator to draw from; each call advances it once.

### Returns
- `Int`: an index into `probabilities`.

### Errors
Throws an `ArgumentError` when the weights sum to zero, which leaves nothing to sample.
"""
function draw_index(probabilities::AbstractVector{<:Real}, rng)::Int
    total = sum(probabilities)
    total > 0 || throw(ArgumentError("Cannot sample from a probability row with zero mass."))

    # drop a uniform point on the line of length `total` -
    target = Random.rand(rng) * total

    # walk the segments, returning the first index whose running total reaches the point -
    cumulative_probability = 0.0
    for index ∈ eachindex(probabilities)
        cumulative_probability += probabilities[index]
        if target ≤ cumulative_probability
            return index
        end
    end

    # only reachable through floating-point rounding, when the running total falls a hair
    # short of `total` and the point landed in that gap; the last index is the right answer.
    return lastindex(probabilities)
end

"""
    sample_sequences(model, number_of_sequences; seed=5800) -> Vector{String}

Generate fixed-length amino-acid sequences from a `PositionAwareMarkovModel`.
Sampling begins from the model's initial distribution and then uses the transition
matrix associated with each alignment position. `seed` controls a local random-
number generator, so the result is reproducible without changing Julia's global RNG.

Each sequence is built left to right: the first amino acid comes from the initial
distribution, and every later one is drawn from the row of the current position's
transition matrix belonging to the amino acid just drawn. Only that one amino acid and the
position decide the next draw, which is what makes the model first order.

### Arguments
- `model::PositionAwareMarkovModel`: a fitted model.
- `number_of_sequences::Integer`: how many sequences to draw; must be positive.
- `seed::Integer`: seeds a generator local to this call, so the same arguments always give
  the same sequences and Julia's global random state is left alone.

### Returns
- `Vector{String}`: the sampled sequences, each of length `model.sequence_length`. Repeats
  are possible, since every draw is independent.

### Errors
Throws an `ArgumentError` if `number_of_sequences` is not positive.
"""
function sample_sequences(
    model::PositionAwareMarkovModel,
    number_of_sequences::Integer;
    seed::Integer = 5800,
)::Vector{String}

    number_of_sequences > 0 || throw(ArgumentError("The number of sequences must be positive."))
    rng = Random.Xoshiro(seed) # a generator of our own, so the global one is untouched
    samples = Vector{String}(undef, number_of_sequences) # room for the results, filled in below

    for sample_index ∈ 1:number_of_sequences
        characters = Vector{Char}(undef, model.sequence_length)

        # the first position comes from the initial distribution -
        current_index = draw_index(model.initial_probabilities, rng)
        characters[1] = model.alphabet[current_index]

        # then walk the chain, one adjacent pair at a time -
        for position ∈ 1:(model.sequence_length - 1)
            # the row for the amino acid we are standing on; view(...) avoids copying it
            probabilities = view(model.transition_probabilities, position, current_index, :)
            current_index = draw_index(probabilities, rng) # this row always has mass: see fit_position_aware_markov
            characters[position + 1] = model.alphabet[current_index]
        end
        samples[sample_index] = String(characters) # Vector{Char} -> String
    end
    return samples
end

"""
    sequence_identity(first_sequence, second_sequence) -> Float64

Return the fraction of aligned positions carrying the same amino acid in two
equal-length sequences. The result lies between zero and one.

One means the sequences agree everywhere, zero that they agree nowhere. Positions are
compared independently, so this measures agreement in an alignment, not similarity after
shifting one sequence against the other.

### Arguments
- `first_sequence`, `second_sequence::AbstractString`: aligned sequences of equal length.

### Returns
- `Float64`: the matching fraction, in `[0, 1]`.

### Errors
Throws an `ArgumentError` if the two sequences have different lengths.
"""
function sequence_identity(first_sequence::AbstractString, second_sequence::AbstractString)::Float64
    length(first_sequence) == length(second_sequence) ||
        throw(ArgumentError("Sequence identity requires equal-length aligned sequences."))
    return count(first_sequence[index] == second_sequence[index] for index ∈ eachindex(first_sequence)) /
        length(first_sequence)
end

"""
    mean_nearest_identity(generated, reference) -> Float64

For each generated sequence, find its largest sequence identity to any reference
sequence and return the mean of those nearest-reference identities.

A high value says the generated sequences sit close to something already in the reference
set; a low value says they sit away from all of it. The cost is one comparison per
generated-reference pair.

### Arguments
- `generated::AbstractVector{<:AbstractString}`: the sequences being scored.
- `reference::AbstractVector{<:AbstractString}`: the sequences to score against.

### Returns
- `Float64`: the mean best identity, in `[0, 1]`.

### Errors
Throws an `ArgumentError` if either collection is empty, or if any pair differs in length.
"""
function mean_nearest_identity(
    generated::AbstractVector{<:AbstractString},
    reference::AbstractVector{<:AbstractString},
)::Float64

    isempty(generated) && throw(ArgumentError("At least one generated sequence is required."))
    isempty(reference) && throw(ArgumentError("At least one reference sequence is required."))
    identities = [maximum(sequence_identity(sequence, stored) for stored ∈ reference) for sequence ∈ generated]
    return sum(identities) / length(identities)
end

"""
    amino_acid_composition(sequences; alphabet=AMINO_ACIDS) -> Vector{Float64}

Compute the pooled amino-acid frequency distribution across a collection of
sequences. The returned vector follows `alphabet` order and sums to one.

Pooled means every position of every sequence is counted once into one shared tally, so
this describes the collection's overall amino-acid usage and says nothing about which
position each amino acid came from.

### Arguments
- `sequences::AbstractVector{<:AbstractString}`: the collection to summarize.
- `alphabet::AbstractVector{Char}`: the symbols to count, fixing the output order.

### Returns
- `Vector{Float64}`: frequencies in `alphabet` order, summing to one.

### Errors
Throws an `ArgumentError` for an empty collection or a character outside `alphabet`.
"""
function amino_acid_composition(
    sequences::AbstractVector{<:AbstractString};
    alphabet::AbstractVector{Char} = AMINO_ACIDS,
)::Vector{Float64}

    isempty(sequences) && throw(ArgumentError("At least one sequence is required."))
    counts = zeros(Float64, length(alphabet))
    state_index = Dict(character => index for (index, character) ∈ enumerate(alphabet))
    for sequence ∈ sequences, character ∈ sequence
        haskey(state_index, character) || throw(ArgumentError("Sequence contains a character outside the alphabet."))
        counts[state_index[character]] += 1
    end
    return counts ./ sum(counts)
end

"""
    kl_divergence(reference, candidate; epsilon=1e-12) -> Float64

Compute the Kullback--Leibler divergence from a reference categorical distribution
to a candidate distribution, that is the sum of `p*log(p/q)` over the entries of the
reference. Both inputs are normalized internally and must be non-negative.

The arguments are not interchangeable: this measures the cost of describing `reference`
using `candidate`, and swapping them generally gives a different number. It is zero exactly
when the two distributions agree, and otherwise positive.

`epsilon` does more than avoid dividing by zero. An entry the candidate never produces
would send the true divergence to infinity; dividing by `max(q, epsilon)` reports a large
finite number instead. Values computed with different `epsilon` are not comparable.

### Arguments
- `reference`, `candidate::AbstractVector{<:Real}`: non-negative vectors of equal length.
- `epsilon::Real`: the positive floor applied to candidate entries.

### Returns
- `Float64`: the divergence in nats, since this uses the natural logarithm.

### Errors
Throws an `ArgumentError` for unequal lengths, a negative entry, or a non-positive `epsilon`.
"""
function kl_divergence(
    reference::AbstractVector{<:Real},
    candidate::AbstractVector{<:Real};
    epsilon::Real = 1e-12,
)::Float64

    length(reference) == length(candidate) || throw(ArgumentError("Distributions must have equal length."))
    all(reference .≥ 0) && all(candidate .≥ 0) || throw(ArgumentError("Distribution entries must be non-negative."))
    epsilon > 0 || throw(ArgumentError("epsilon must be positive."))
    reference_probabilities = reference ./ sum(reference)
    candidate_probabilities = candidate ./ sum(candidate)
    return sum(probability * log(probability / max(candidate_probabilities[index], epsilon))
        for (index, probability) ∈ enumerate(reference_probabilities) if probability > 0)
end

"""
    conserved_positions(sequences, residue; threshold=0.95) -> Vector{Int}

Return alignment positions where at least `threshold` of the sequences carry
`residue`. Positions use Julia's one-based indexing.

The threshold is a fraction of the sequences, not a count, and the comparison is inclusive,
so a position is kept when its frequency equals the threshold exactly.

### Arguments
- `sequences::AbstractVector{<:AbstractString}`: equal-length aligned sequences.
- `residue::Char`: the amino acid to look for.
- `threshold::Real`: the smallest qualifying fraction, between zero and one.

### Returns
- `Vector{Int}`: the qualifying positions, in increasing order; empty if none qualify.

### Errors
Throws an `ArgumentError` for an empty collection, a threshold outside `[0, 1]`, or
sequences of unequal length.
"""
function conserved_positions(
    sequences::AbstractVector{<:AbstractString},
    residue::Char;
    threshold::Real = 0.95,
)::Vector{Int}

    isempty(sequences) && throw(ArgumentError("At least one sequence is required."))
    0 ≤ threshold ≤ 1 || throw(ArgumentError("threshold must lie between zero and one."))
    sequence_length = length(first(sequences))
    all(length(sequence) == sequence_length for sequence ∈ sequences) ||
        throw(ArgumentError("Sequences must have equal length."))
    return [position for position ∈ 1:sequence_length
        if count(sequence -> sequence[position] == residue, sequences) / length(sequences) ≥ threshold]
end

"""
    position_frequency(sequences, position, residues) -> Float64

Return the fraction of aligned sequences whose amino acid at `position` belongs
to `residues`. Positions use Julia's one-based indexing.

### Arguments
- `sequences::AbstractVector{<:AbstractString}`: the collection to measure.
- `position::Integer`: the alignment position to inspect.
- `residues`: any collection of `Char`, such as a vector or a string; membership is all
  that is used.

### Returns
- `Float64`: the qualifying fraction, in `[0, 1]`.

### Errors
Throws an `ArgumentError` for an empty collection, and a `BoundsError` if `position` lies
outside some sequence.
"""
function position_frequency(
    sequences::AbstractVector{<:AbstractString},
    position::Integer,
    residues,
)::Float64

    isempty(sequences) && throw(ArgumentError("At least one sequence is required."))
    all(1 ≤ position ≤ length(sequence) for sequence ∈ sequences) ||
        throw(BoundsError(first(sequences), position))
    allowed = Set(residues)
    return count(sequence -> sequence[position] ∈ allowed, sequences) / length(sequences)
end

"""
    scaffold_retention(sequences, positions; residue='C') -> Float64

Return the fraction of sequences carrying `residue` at every position in
`positions`. This metric is used for the conserved cysteine scaffold in the
Kunitz-family example.

A sequence counts only when it carries `residue` at every one of the positions, so this is
an all-or-nothing test per sequence rather than an average over positions.

### Arguments
- `sequences::AbstractVector{<:AbstractString}`: the collection to measure.
- `positions::AbstractVector{<:Integer}`: the positions that must all match.
- `residue::Char`: the amino acid required at each of them.

### Returns
- `Float64`: the fraction keeping the whole set, in `[0, 1]`.

### Errors
Throws an `ArgumentError` if the collection or the position list is empty.
"""
function scaffold_retention(
    sequences::AbstractVector{<:AbstractString},
    positions::AbstractVector{<:Integer};
    residue::Char = 'C',
)::Float64

    isempty(sequences) && throw(ArgumentError("At least one sequence is required."))
    isempty(positions) && throw(ArgumentError("At least one scaffold position is required."))
    return count(sequence -> all(sequence[position] == residue for position ∈ positions), sequences) /
        length(sequences)
end

"""
    pairwise_diversity(sequences; number_of_pairs=2000, seed=5801) -> Float64

Estimate mean pairwise sequence diversity, defined as one minus sequence identity,
from randomly drawn sequence pairs. `seed` controls a local RNG.

The result is an estimate, not an exact average, whenever sampling is used. When
`number_of_pairs` reaches or exceeds the number of distinct unordered pairs, every pair is
compared and the answer is exact. Otherwise index pairs are drawn at random with
replacement, rejecting only draws that name the same sequence twice, so one unordered pair
can be counted more than once.

Zero means the sequences are identical, and larger values mean they share less.

### Arguments
- `sequences::AbstractVector{<:AbstractString}`: at least two equal-length sequences.
- `number_of_pairs::Integer`: how many pairs to compare; must be positive.
- `seed::Integer`: seeds a local generator, so the estimate is reproducible.

### Returns
- `Float64`: one minus the mean identity, in `[0, 1]`.

### Errors
Throws an `ArgumentError` for fewer than two sequences or a non-positive `number_of_pairs`.
"""
function pairwise_diversity(
    sequences::AbstractVector{<:AbstractString};
    number_of_pairs::Integer = 2000,
    seed::Integer = 5801,
)::Float64

    length(sequences) ≥ 2 || throw(ArgumentError("At least two sequences are required."))
    number_of_pairs > 0 || throw(ArgumentError("number_of_pairs must be positive."))
    total_pairs = length(sequences) * (length(sequences) - 1) ÷ 2

    # few enough pairs to enumerate: compare every one and get the exact answer -
    if number_of_pairs ≥ total_pairs
        identities = [sequence_identity(sequences[first_index], sequences[second_index])
            for first_index ∈ 1:(length(sequences) - 1)
            for second_index ∈ (first_index + 1):length(sequences)]
    # otherwise sample pairs; with replacement, so a pair may recur -
    else
        rng = Random.Xoshiro(seed)
        identities = Float64[]
        while length(identities) < number_of_pairs
            first_index = Random.rand(rng, eachindex(sequences))
            second_index = Random.rand(rng, eachindex(sequences))
            first_index == second_index && continue # a sequence against itself is always identity 1
            push!(identities, sequence_identity(sequences[first_index], sequences[second_index]))
        end
    end
    return 1 - sum(identities) / length(identities)
end

end # module L11bProteinMarkov
