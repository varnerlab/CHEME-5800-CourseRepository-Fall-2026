# =============================================================================
# CHEME 5800 | L11b reference solution: the character transition matrix
# =============================================================================
# The completed my_transition_matrix(...). Apart from this header, the TODO
# comments, and the completed lines, it matches the student file, Compute.jl,
# and it uses the same module name, so either file can be loaded in place of
# the other. The notebook has no other exercise answers.
# =============================================================================
module L11bMarkov

export my_transition_matrix

"""
    my_transition_matrix(vocabulary::Dict{Char,Set{String}}, characters::Array{Char,1}) -> Array{Float64,2}

Estimate the transition matrix of a character-level Markov chain from the first two
characters of each word in `vocabulary`.

Entry `P[i, j]` is the fraction of the words that start with `characters[i]` whose second
character is `characters[j]`. For each starting character, the function counts how often each
character comes second, then divides the counts by their total, so every row with at least one
count sums to one.

### Arguments
- `vocabulary::Dict{Char,Set{String}}`: the words, grouped by their first character.
  `vocabulary['b']` is the set of words that start with `'b'`. Every character in
  `characters` must be a key.
- `characters::Array{Char,1}`: the states of the Markov chain, for example `'a'` through `'z'`.
  Row `i` and column `i` of the result belong to `characters[i]`.

### Returns
- `Array{Float64,2}`: the `K × K` transition matrix, where `K = length(characters)`. A word with
  fewer than two characters, or whose second character is not in `characters`, is skipped. A
  character with no counted words gets a row of zeros.

### Example
```julia
characters = [Char(i) for i in 'a':'z']; # the 26 lowercase letters
P = L11bMarkov.my_transition_matrix(vocabulary_data_dictionary, characters);
```
"""
function my_transition_matrix(vocabulary::Dict{Char,Set{String}}, characters::Array{Char,1})::Array{Float64,2}

    # Initialize; this part is complete -
    K = length(characters); # the number of states
    counts = zeros(Int64, K, K); # counts[i, j]: words that start with characters[i] and have characters[j] second
    P = zeros(Float64, K, K); # the transition matrix
    number_of_words_counted = 0; # words with a second character in characters

    # Count the second character of every word -
    for i ∈ 1:K
        for word ∈ vocabulary[characters[i]] # every word that starts with characters[i]

            # a word needs at least two characters; this part is complete -
            if length(word) < 2
                continue;
            end

            # TODO 1: the second character of the word -
            next_char = word[2];

            # find its column, and skip a character that is not a state; this part is complete -
            j = findfirst(x -> x == next_char, characters);
            if isnothing(j)
                continue;
            end
            number_of_words_counted += 1;

            # TODO 2: count the pair (characters[i], characters[j]) -
            counts[i, j] = counts[i, j] + 1;
        end
    end

    # Turn the counts into probabilities, one row at a time -
    for i ∈ 1:K
        N = sum(counts[i, :]); # the number of words counted in row i; this part is complete
        if N > 0

            # TODO 3: divide the counts in row i by N -
            P[i, :] = counts[i, :] ./ N;
        end
    end

    # We get here after counting every word. Every counted word adds one to counts, and every
    # row with counts must sum to one. This part is complete -
    if sum(counts) != number_of_words_counted || any(abs(sum(P[i, :]) - 1) > 1e-10 for i ∈ 1:K if sum(counts[i, :]) > 0)
        throw(ErrorException("Oooops! The `my_transition_matrix(...)` function is not implemented yet - " *
                             "we'd better fix that. Complete TODO 1 through TODO 3."))
    end
    return P;
end

end # module L11bMarkov
