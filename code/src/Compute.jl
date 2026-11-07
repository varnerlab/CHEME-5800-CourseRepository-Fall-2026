# ------------------------------------------------------------------------------------------------ #
# Compute.jl
#
# Computations on text and market data that the course notebooks call directly:
#
#   tokenize(...)                      turns a sentence into a vector of integer token codes
#                                      [no Fall 2026 notebook calls it]
#   log_growth_matrix(...)             computes the daily growth rate of each firm's share price
#                                      [week-10 L10b weighted majority lab]
#   vocabulary_transition_matrix(...)  estimates, for each first letter of a word, the probability
#                                      of each second letter [week-11 L11b Markov word generator lab]
#   sample_words(...)                  generates random words, one letter at a time, from a
#                                      transition matrix [week-11 L11b Markov word generator lab]
#
# DataFrame and nrow come from the DataFrames package, and Categorical from the Distributions
# package. VLDataScienceMachineLearningPackage.jl loads both.
# ------------------------------------------------------------------------------------------------ #

# -- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------- #
"""
    tokenize(s::String, tokens::Dict{String, Int64};
        pad::Int64 = 0, padleft::Bool = false, delim::Char = ' ') -> Array{Int64,1}

Convert a sentence into a vector of integer token codes.

We split the sentence `s` into words at each `delim` character, and look up the integer code of
each word in the vocabulary `tokens`. A word that is not in the vocabulary gets the code of the
unknown token `<unk>`. Two delimiters in a row give an empty word, which also gets the code of
`<unk>` unless the empty string is in `tokens`. We put the code of `<bos>` (beginning of sequence)
first and the code of `<eos>` (end of sequence) last.

Padding makes several sentences the same length, so they can be stored side by side. When
`pad > 0`, we add `<pad>` codes until the vector holds `pad` codes, counting `<bos>` but not
`<eos>`. Then we add `<eos>`. So the result holds `max(N, pad) + 1` codes, where `N` is the number of
codes before padding (`<bos>` plus one per word). A sentence that already holds `pad` or more codes
gets no padding.

### Arguments
- `s::String`: the sentence to convert, for example `"the cat sat"`.
- `tokens::Dict{String, Int64}`: the vocabulary. Each key is a word or a control token, and its
  value is the integer code. It must contain the control tokens `"<bos>"`, `"<eos>"`, and `"<unk>"`,
  and also `"<pad>"` when `pad > 0`.
- `pad::Int64 = 0`: the length to pad to, counting `<bos>` but not `<eos>`. The default `0` means
  no padding.
- `padleft::Bool = false`: if `true`, the `<pad>` codes go at the front, before `<bos>`; if `false`,
  they go at the end, before `<eos>`.
- `delim::Char = ' '`: the character that separates the words in `s`.

### Returns
- `Array{Int64,1}`: the codes in order: the `<pad>` codes (left padding only), `<bos>`, one code per
  word, the `<pad>` codes (right padding only), and `<eos>`.

### Throws
- a `KeyError` if `tokens` does not contain a control token that the function needs.

### Example
```julia
tokens = Dict("<bos>" => 1, "<eos>" => 2, "<pad>" => 3, "<unk>" => 4, "the" => 5, "cat" => 6);
tokenize("the cat sat", tokens)                         # returns [1, 5, 6, 4, 2]
tokenize("the cat", tokens; pad = 5)                    # returns [1, 5, 6, 3, 3, 2]
tokenize("the cat", tokens; pad = 5, padleft = true)    # returns [3, 3, 1, 5, 6, 2]
```
"""
function tokenize(s::String, tokens::Dict{String, Int64};
    pad::Int64 = 0, padleft::Bool = false, delim::Char = ' ')::Array{Int64,1}

    # initialize: an empty vector of token codes -
    tokenarray = Array{Int64,1}();

    # The control tokens. This function uses four of them, and `tokens` must hold their codes:
    #   "<bos>": beginning of sequence, the first code;
    #   "<eos>": end of sequence, the last code;
    #   "<pad>": padding, which fills a short sentence up to the length pad;
    #   "<unk>": unknown, the code of any word that is not in the vocabulary (out of vocabulary).
    # A fifth control token, "<mask>", is not used here.

    # split the string into words, and look up the code of each word -
    push!(tokenarray, tokens["<bos>"]); # beginning of sequence: always the first code
    fields = split(s, delim) .|> String; # split cuts s at each delim; .|> String passes each piece to String (the dot applies |> to every piece), turning each piece into its own String
    for field ∈ fields
        if haskey(tokens, field) # is this word in the vocabulary?
            push!(tokenarray, tokens[field]); # yes: add its code
        else
            push!(tokenarray, tokens["<unk>"]); # no: add the code of the unknown token
        end
    end

    # -- PAD LOGIC ----------------------------------------------------------- #
    # Do we need to pad? We add <pad> codes until the vector holds pad codes. N is the number of
    # codes so far, so (N+1):pad has pad − N entries, one per <pad> code, and it is empty when
    # N ≥ pad. foreach(f, list) calls the function f once for each entry of the list; here
    # i -> push!(...) is an anonymous function (a function without a name) that ignores i and adds
    # one <pad> code -
    if (padleft == false && pad > 0)
        N = length(tokenarray); # the number of codes so far: <bos> plus one per word
        foreach(i->push!(tokenarray, tokens["<pad>"]), (N+1):pad); # pad right: push! adds each <pad> code to the end
    elseif (padleft == true && pad > 0)
        N = length(tokenarray); # the number of codes so far: <bos> plus one per word
        foreach(i->pushfirst!(tokenarray, tokens["<pad>"]), (N+1):pad); # pad left: pushfirst! adds each <pad> code to the front
    end
    # ----------------------------------------------------------------------- #
    push!(tokenarray, tokens["<eos>"]); # end of sequence: always the last code

    # return the vector of token codes -
    return tokenarray;
end

"""
    log_growth_matrix(dataset::Dict{String, DataFrame}, firms::Array{String,1};
        Δt::Float64 = (1.0/252.0), risk_free_rate::Float64 = 0.0, testfirm = "AAPL",
        keycol::Symbol = :volume_weighted_average_price) -> Array{Float64,2}

Compute the growth rate of each firm's share price between each pair of consecutive trading days.

We assume the share price grows with continuous compounding over each time step:
`Sⱼ = Sⱼ₋₁⋅exp(g⋅Δt)`, where `Sⱼ` is the share price on trading day `j` (units: USD/share), `Δt` is
the length of one time step (units: years), and `g` is the growth rate (units: 1/years). Solving
for `g` and subtracting the annual risk-free rate `r_f` (units: 1/years) gives the excess growth
rate that we store:

`g = (1/Δt)⋅ln(Sⱼ/Sⱼ₋₁) − r_f`,

where `ln` is the natural logarithm. With the default `r_f = 0`, `g` is the growth rate of the
week-10 L10b lab.

### Arguments
- `dataset::Dict{String, DataFrame}`: the price data. Each key is a ticker symbol, such as `"AAPL"`,
  and its value is a DataFrame with one row per trading day, in date order.
- `firms::Array{String,1}`: the ticker symbols of the firms we want, in the column order we want.
- `Δt::Float64 = 1/252`: the length of one time step, in years. The default is one trading day,
  because a year has about 252 trading days.
- `risk_free_rate::Float64 = 0.0`: the annual risk-free rate `r_f`, in 1/years.
- `testfirm = "AAPL"`: the ticker whose number of rows sets the number of trading days. Every firm
  in `firms` must have at least this many rows.
- `keycol::Symbol = :volume_weighted_average_price`: the DataFrame column that holds the price `S`.

### Returns
- `Array{Float64,2}`: the growth matrix, with `T − 1` rows and one column per firm, where `T` is the
  number of rows of the test firm. Row `j−1` holds the growth from trading day `j−1` to trading day
  `j`, and column `i` belongs to `firms[i]`.

### Throws
- a `KeyError` if `testfirm`, or a ticker in `firms`, is not a key of `dataset`.
- an error if a firm has fewer rows than the test firm, or if `keycol` is not a column of its
  DataFrame.
"""
function log_growth_matrix(dataset::Dict{String, DataFrame},
    firms::Array{String,1}; Δt::Float64 = (1.0/252.0), risk_free_rate::Float64 = 0.0,
    testfirm="AAPL", keycol::Symbol = :volume_weighted_average_price)::Array{Float64,2}

    # initialize -
    number_of_firms = length(firms); # one column per firm
    number_of_trading_days = nrow(dataset[testfirm]); # nrow counts the rows (trading days) of the test firm's DataFrame
    return_matrix = Array{Float64,2}(undef, number_of_trading_days-1, number_of_firms); # undef: the entries are not set yet; the loops below fill every entry

    # main loop: one firm (one column) each pass -
    for i ∈ eachindex(firms) # eachindex gives the positions 1, 2, ..., length(firms)

        # get the price data of firm i -
        firm_index = firms[i]; # the ticker symbol of firm i, such as "AAPL" (a name, not a number)
        firm_data = dataset[firm_index]; # the DataFrame of firm i

        # compute the growth rate between each pair of consecutive trading days -
        for j ∈ 2:number_of_trading_days
            S₁ = firm_data[j-1, keycol]; # the price on day j-1: row j-1, column keycol
            S₂ = firm_data[j, keycol]; # the price on day j: row j, column keycol
            return_matrix[j-1, i] = (1/Δt)*(log(S₂/S₁)) - risk_free_rate; # g = (1/Δt)⋅ln(S₂/S₁) − r_f; log is the natural logarithm
        end
    end

    # return the growth matrix: rows are time steps, columns are firms -
    return return_matrix;
end

"""
    vocabulary_transition_matrix(wordsdictionary::Dict{Char, Set{String}},
        letters::Array{Char,1}) -> Array{Float64,2}

Estimate, for each first letter of a word, the probability of each second letter.

Row `i` of the matrix `P` belongs to the letter `letters[i]`, and column `j` to the letter
`letters[j]`. We look at every word that starts with `letters[i]` and has at least two letters,
and count how often its second letter is `letters[j]`:

`P[i,j] = nᵢⱼ / Nᵢ`,

where `nᵢⱼ` is the number of words that start with `letters[i]` and have `letters[j]` as their
second letter, and `Nᵢ` is the number of words that start with `letters[i]` and have at least two
letters. One-letter words are skipped. Each row of `P` sums to one, so the week-11 L11b lab uses
`P` as the transition matrix of a Markov chain over letters. The lab also checks the student's own
matrix against this one.

### Arguments
- `wordsdictionary::Dict{Char, Set{String}}`: the vocabulary, grouped by first letter, as returned
  by `MyEnglishLanguageVocabularyModel()`. Each key is a letter, and its value is the set of words
  that start with that letter.
- `letters::Array{Char,1}`: the letters that label the rows and columns of `P`, in order. The matrix
  is always `26 × 26`, so `letters` should hold the 26 letters `'a'` to `'z'`.

### Returns
- `Array{Float64,2}`: the `26 × 26` transition matrix `P`. If no word that starts with `letters[i]`
  has a second letter, row `i` is `NaN` (not a number), because we divide zero by zero.

### Throws
- a `KeyError` if a letter in `letters` is not a key of `wordsdictionary`.
- an error if the second character of a word is not in `letters`, because `findfirst` then
  returns `nothing`, which is not a valid index.
"""
function vocabulary_transition_matrix(wordsdictionary::Dict{Char, Set{String}},
    letters::Array{Char,1})::Array{Float64,2}

    # initialize -
    number_of_letters = 26; # the matrix is always 26 × 26: one row and one column per letter
    counts = Array{Int64,1}(undef, number_of_letters); # counts[j]: the number of words whose second letter is letters[j]
    P = Array{Float64, 2}(undef, number_of_letters, number_of_letters); # the transition matrix; undef means the entries are not set yet
    fill!(P, 0.0); # initially all the elements are zero
    fill!(counts,0.0); # initially counts has all zeros (0.0 is stored as the integer 0)

    # main loop: one first letter (one row of P) each pass -
    for i ∈ eachindex(letters) # eachindex gives the positions 1, 2, ..., length(letters)
        startchar = letters[i]; # the first letter that row i belongs to

        # get all the words that start with startchar. We copy the set, because pop! below
        # removes words, and we must not empty the caller's dictionary -
        set_of_words = wordsdictionary[startchar] |> copy; # |> passes the set to copy, which returns a new set with the same words
        N = 0; # the number of words with at least two letters that we have counted
        while (isempty(set_of_words) == false) # repeat until the copy is empty
            word = pop!(set_of_words); # remove one word from the copy, and keep it in word (a Set has no order)

            # count the second letter of the word; we skip one-letter words -
            if (length(word) ≥ 2)
                next_char = word[2]; # the second character in the word
                j = findfirst(x-> x == next_char, letters); # the position of next_char in letters: x -> x == next_char is an anonymous function that tests one letter, and findfirst returns the first position where it is true
                counts[j] = counts[j] + 1; # one more word with second letter letters[j]
                N += 1; # one more counted word (N += 1 means N = N + 1)
            end
        end

        # fill in row i of P: the fraction of counted words with each second letter -
        for k ∈ 1:number_of_letters
            P[i,k] = counts[k]/N;
        end

        # reset the counts to zero for the next first letter -
        fill!(counts,0.0); # 0.0 is stored as the integer 0
    end

    # return the transition matrix -
    return P;
end

"""
    sample_words(P::Array{Float64,2}, letters::Array{Char,1};
        number_of_samples::Int64 = 100, length_of_sample_word::Int64 = 4,
        startchar::Char = 'z') -> Dict{Int64,String}

Generate random words, one letter at a time, from a Markov chain over letters.

Each word starts with the letter `startchar`. To choose the next letter, we look up the row of `P`
that belongs to the current letter, and draw from that row: when the current letter is
`letters[i]`, the next letter is `letters[j]` with probability `P[i,j]`. The new letter becomes the
current letter, and we repeat until the word holds `length_of_sample_word` letters. The week-11
L11b lab uses this function with the matrix from `vocabulary_transition_matrix`, and counts how
many generated words are real English words.

The draws use Julia's global random number generator. To get the same words on every run, call
`Random.seed!(...)` before this function, as the L11b lab does.

### Arguments
- `P::Array{Float64,2}`: the transition matrix. Row `i` and column `i` belong to `letters[i]`. Every
  row must be a probability distribution: entries zero or larger that sum to one.
- `letters::Array{Char,1}`: the letters that label the rows and columns of `P`, in order.
- `number_of_samples::Int64 = 100`: the number of words to generate.
- `length_of_sample_word::Int64 = 4`: the number of letters in each word, counting `startchar`.
- `startchar::Char = 'z'`: the first letter of every word. It must be in `letters`.

### Returns
- `Dict{Int64,String}`: the generated words. The keys are `1, 2, …, number_of_samples`, and the
  value of key `i` is word `i`. The same word can appear under several keys.

### Throws
- a `KeyError` if `startchar` is not in `letters`.
- an error if a row of `P` is not a probability distribution.
"""
function sample_words(P::Array{Float64,2}, letters::Array{Char,1};
    number_of_samples::Int64 = 100, length_of_sample_word::Int64 = 4,
    startchar::Char = 'z')::Dict{Int64,String}


    # initialize: every word starts with this letter -
    sample_word_start_char = startchar;

    # build a dictionary from position to letter: letterindexmap[j] is letters[j] -
    letterindexmap = Dict{Int64,Char}()
    for i ∈ eachindex(letters)
        letterindexmap[i] = letters[i];
    end

    # build one probability distribution per letter, from its row of P. Categorical (from the
    # Distributions package) describes a random draw of a position 1, 2, ..., n, where n is the
    # number of columns of P and position j has probability P[i,j] -
    state_distribution_dictionary = Dict{Char,Categorical}();
    for i ∈ eachindex(letters)
        letter = letters[i];
        state_distribution_dictionary[letter] = Categorical(P[i,:]); # P[i,:] is row i of P
    end

    # main loop: build one word each pass -
    generated_word_dictionary = Dict{Int64,String}();
    for i ∈ 1:number_of_samples
        current_char = sample_word_start_char; # every word starts with startchar

        # the letters of this word, as a vector of characters -
        wordvector = Array{Char,1}();
        push!(wordvector,current_char);
        for _ ∈ 2:length_of_sample_word # the loop variable _ means we do not use the counter; we repeat length_of_sample_word − 1 times
            d = state_distribution_dictionary[current_char]; # the distribution of the next letter, given the current letter
            next_char = rand(d) |> k-> letterindexmap[k]; # rand(d) draws a position k; |> passes k to the anonymous function k -> letterindexmap[k], which returns the letter at that position
            push!(wordvector,next_char);
            current_char = next_char; # the new letter becomes the current letter
        end

        # join the characters into one String, and store it under key i -
        generated_word_dictionary[i] = wordvector |> join # |> passes the vector to join, which glues the characters into one String
    end

    # return the dictionary of generated words -
    return generated_word_dictionary;
end

# -- PUBLIC METHODS ABOVE HERE -------------------------------------------------------------------- #
