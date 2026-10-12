# =============================================================================
# CHEME 5800 | L11b student work: the character transition matrix
# =============================================================================
# This is the file you edit in this lab. Complete my_transition_matrix(...)
# below by filling in the lines marked TODO 1, TODO 2, and TODO 3; everything
# else is already written. Together, the three TODOs count how often each
# character comes second in a word and turn the counts into probabilities.
#
# After each edit: save this file, re-run the setup cell at the top of the
# notebook to reload it, then re-run the Task 1 cell and the check cell.
# You are done when every test in the check cell passes.
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

            # TODO 1: the second character of the word. Replace characters[1] with the
            # character in position 2 of word. Hint: word[2] is that character.
            next_char = characters[1];

            # find its column, and skip a character that is not a state; this part is complete -
            j = findfirst(x -> x == next_char, characters);
            if isnothing(j)
                continue;
            end
            number_of_words_counted += 1;

            # TODO 2: count the pair (characters[i], characters[j]). Replace the right-hand
            # side so that counts[i, j] goes up by one.
            counts[i, j] = counts[i, j];
        end
    end

    # Turn the counts into probabilities, one row at a time -
    for i ∈ 1:K
        N = sum(counts[i, :]); # the number of words counted in row i; this part is complete
        if N > 0

            # TODO 3: turn row i of counts into probabilities. Replace the right-hand side so
            # that every entry of row i is divided by N. Hint: counts[i, :] ./ N divides
            # each entry by N.
            P[i, :] = counts[i, :];
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
