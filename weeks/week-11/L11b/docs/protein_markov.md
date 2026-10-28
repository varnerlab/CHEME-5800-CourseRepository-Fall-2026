# Position-aware protein Markov model reference

[Back to the protein-generator example](../CHEME-5800-L11b-Example-MarkovProteinGenerator-Fall-2026.ipynb)

The functions below are defined in [`src/ProteinMarkov.jl`](../src/ProteinMarkov.jl)
inside the `L11bProteinMarkov` module. Protein sequences use the 20 standard
one-letter amino-acid symbols and alignment positions use Julia's one-based
indexing.

## `read_fasta`

```julia
read_fasta(path::AbstractString) -> Vector{NamedTuple}
```

Read a FASTA file and return records with `id::String` and `sequence::String`
fields. Wrapped sequence lines are concatenated. The function rejects empty
records and sequence data appearing before the first FASTA header.

## `standard_alignment`

```julia
standard_alignment(records; alphabet=AMINO_ACIDS) -> Vector{String}
```

Keep the records written entirely in `alphabet`, and require the kept records to
share one length, throwing an `ArgumentError` if they do not. The function filters
on the alphabet, not on length: the example uses it to drop aligned records holding
a gap or a non-standard amino-acid symbol before fitting the model.

## `fit_position_aware_markov`

```julia
fit_position_aware_markov(sequences;
    alphabet=AMINO_ACIDS,
    weights=ones(length(sequences))) -> PositionAwareMarkovModel
```

Estimate the initial amino-acid distribution and one first-order transition
matrix for each adjacent pair of alignment positions. `weights[k]` is the
non-negative relative count assigned to sequence `k`; uniform weights give the
ordinary empirical model. The return value contains the alphabet, initial
probabilities, three-dimensional transition array, and sequence length.

## `sample_sequences`

```julia
sample_sequences(model, number_of_sequences; seed=5800) -> Vector{String}
```

Generate fixed-length sequences from a fitted model. The seed initializes a
local random-number generator, so repeated calls with the same inputs produce
the same sequences without changing Julia's global random-number state.

## Evaluation functions

```julia
amino_acid_composition(sequences; alphabet=AMINO_ACIDS) -> Vector{Float64}
kl_divergence(reference, candidate; epsilon=1e-12) -> Float64
mean_nearest_identity(generated, reference) -> Float64
pairwise_diversity(sequences; number_of_pairs=2000, seed=5801) -> Float64
conserved_positions(sequences, residue; threshold=0.95) -> Vector{Int}
position_frequency(sequences, position, residues) -> Float64
scaffold_retention(sequences, positions; residue='C') -> Float64
```

The composition vector is a normalized pooled amino-acid count. Sequence identity
and diversity, position frequency, and scaffold retention are fractions between
zero and one. None of these quantities carries units.

Two behaviors matter when comparing the numbers.

`kl_divergence(reference, candidate)` returns the divergence from `reference` to
`candidate`, that is the sum of `p*log(p/q)` over the entries of `reference`, so the
arguments are not interchangeable. It divides by `max(q, epsilon)` rather than by `q`,
so an entry the candidate never produces gives a large finite value instead of an
infinite one. Values from runs with different `epsilon` are not comparable.

`pairwise_diversity(sequences)` is an estimate, not an exact average. When the
requested `number_of_pairs` is at least the number of distinct unordered pairs, it
uses every pair; otherwise it draws index pairs at random with replacement, rejecting
only the pairs that name the same sequence twice, so one unordered pair can be drawn
more than once. A local random-number generator seeded with `seed` makes the estimate
reproducible.

## `onehot_matrix`

```julia
onehot_matrix(sequences; alphabet=AMINO_ACIDS) -> Array{Float64,2}
```

Encode equal-length aligned sequences as an `n` by `L*q` matrix, one row per sequence,
where `L` is the aligned length and `q` the alphabet size. Column `(l - 1)*q + i` holds
the indicator for alphabet symbol `i` at position `l`, so every row has exactly `L`
nonzero entries and the mean of a column is the family frequency of that amino acid at
that position. The example centers this matrix and takes its singular value
decomposition.
