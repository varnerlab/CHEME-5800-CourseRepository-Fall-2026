# ------------------------------------------------------------------------------------------------ #
# Files.jl
#
# The data-loading functions of the course package. Most of them read one file, or one folder,
# from the code/src/data folder and return its contents as Julia data. The two edge-list readers
# instead read a file whose path we pass in.
#
# Public functions (the notebooks that use each one are in brackets):
#   MyTrainingMarketDataSet()              daily S&P 500 price records, from a .jld2 file
#                                          [no Fall 2026 notebook; the week-10 L10b lab reads a
#                                          CSV copy of the prices from its own data folder]
#   MyStringDecodeChallengeDataset()       three text files of lines, as a NamedTuple
#                                          [no Fall 2026 notebook]
#   MyCommonSurnameDataset()               common surnames by country, as a DataFrame
#                                          [no Fall 2026 notebook]
#   MyCommonForenameDataset()              common first names by country, as a DataFrame
#                                          [no Fall 2026 notebook]
#   MyKaggleHousingPricesDataset()         house prices and house features, as a DataFrame
#                                          [week-07 L7d lab, week-08 L8d lab]
#   MyBanknoteAuthenticationDataset()      banknote image features and labels, as a DataFrame
#                                          [week-09 L9a example, week-09 L9d lab]
#   MyEnglishLanguageVocabularyModel()     about 370,000 English words, grouped by first letter
#                                          [week-11 L11b lab]
#   MyGraphEdgeModels(...)                 reads an edge-list file into a dictionary of edge models
#                                          [week-04 L4b lab, week-04 L4d lab]
#   MyConstrainedGraphEdgeModels(...)      reads an edge-list file with flow bounds into a
#                                          dictionary of edge models [week-05 L5a worked example,
#                                          through build_flow_graph in FlowValidation.jl, and the
#                                          week-05 L5b lab]
#   MyMNISTHandwrittenDigitImageDataset()  images of the handwritten digits 0 to 9
#                                          [no Fall 2026 notebook]
#
# Private helpers (the leading underscore marks a function for use inside this package only):
#   _puzzleparse(...)     reads a text file into a vector of lines
#   _jld2(...)            reads every variable stored in a .jld2 file into a dictionary
#   _file_extension(...)  returns the extension of a file name, such as "jpg"
#
# Only three data files ship in code/src/data in this repository:
# Housing-Training-Dataset-Kaggle.csv, data-banknote-authentication.csv, and words_dictionary.json.
# The loaders of the other files stop with an error here, because their files are missing.
#
# The constant _PATH_TO_DATA, the full path of the data folder, is set in
# VLDataScienceMachineLearningPackage.jl. That file also loads the packages used here: CSV (reads
# comma-separated files), DataFrames (tables), FileIO (its load function reads .jld2 files, with
# JLD2, and image files), JSON (reads .json files), and Images (the Gray pixel type and the N0f8
# number type).
# ------------------------------------------------------------------------------------------------ #

# -- PRIVATE FUNCTIONS BELOW HERE ------------------------------------------------------------------------------ #
"""
    _puzzleparse(filepath::String) -> Vector{String}

Read a text file, one line at a time, and return its lines with the whitespace at both ends
removed. `MyStringDecodeChallengeDataset()` uses this function for each of its three files.

### Arguments
- `filepath::String`: the full path of the text file.

### Returns
- `Vector{String}`: one entry per line of the file, in file order, without the newline character
  and without spaces or tabs at either end. An empty line gives an empty string `""`.

### Throws
- a `SystemError` if no file exists at `filepath`.
"""
function _puzzleparse(filepath::String)::Vector{String}

    # initialize: an empty vector that will hold the lines -
    result = Vector{String}();

    # read the file one line at a time. The do block opens the file, names the open file io, runs
    # the block, and closes the file when the block ends, even if an error occurs -
    open(filepath, "r") do io
        for line ∈ eachline(io) # eachline gives each line as a String, without the newline character
            push!(result, strip(line)); # cutoff whitespace: strip removes spaces and tabs at both ends, and push! adds the line to the end of result
        end
    end

    # return the lines -
    return result;
end

"""
    _jld2(path::String) -> Dict{String,Any}

Read every variable stored in a `.jld2` file, and return them in a dictionary. JLD2 is a file
format that saves Julia variables, such as dictionaries and DataFrames, so they can be read back
exactly as they were. `MyTrainingMarketDataSet()` uses this function.

### Arguments
- `path::String`: the full path of the `.jld2` file.

### Returns
- `Dict{String,Any}`: one entry per saved variable. The key is the variable's name, and the value
  is the variable itself.
"""
function _jld2(path::String)::Dict{String,Any}
    return load(path); # load (from FileIO) sees the .jld2 extension and reads the file with the JLD2 package
end

"""
    _file_extension(file::String) -> String

Return the extension of a file name: the text after its last period. For example, the extension
of `"img_1.jpg"` is `"jpg"`. `MyMNISTHandwrittenDigitImageDataset()` uses this function to keep only
the `.jpg` image files.

### Arguments
- `file::String`: a file name, such as `"img_1.jpg"`.

### Returns
- `String`: the characters after the last `.` in `file`, without the period.

### Throws
- an error if `file` contains no period, because `findlast` then returns `nothing`, and
  `nothing + 1` is not defined.
"""
_file_extension(file::String) = file[findlast(==('.'), file)+1:end]; # helper function to get the file extension. This is a one-line function definition. ==('.') is a function that tests whether a character equals '.'; findlast returns the position of the last '.', and file[position+1:end] is the text after it

# -- PRIVATE FUNCTIONS ABOVE HERE ------------------------------------------------------------------------------ #

# -- PUBLIC FUNCTIONS BELOW HERE ------------------------------------------------------------------------------- #

"""
    MyTrainingMarketDataSet() -> Dict{String,Any}

Load daily price records for the firms in the S&P 500 index and a few exchange-traded funds, from
January 3, 2014, to December 31, 2024. Each record holds a day's prices, including the open, high,
low, and close (OHLC) prices. [Polygon.io](https://polygon.io/) provided the data.

The function reads the file `SP500-Daily-OHLC-1-3-2014-to-12-31-2024.jld2` from `code/src/data`.
That file is 88 MB and is not included in this repository, so this call stops with an error here.
The week-10 L10b lab reads a smaller CSV copy of the prices from its own `data` folder instead.

### Returns
- `Dict{String,Any}`: the variables stored in the file, by name. Past offerings of the course read
  the entry `"dataset"`, a dictionary with one DataFrame of daily records per ticker symbol.
"""
MyTrainingMarketDataSet() = _jld2(joinpath(_PATH_TO_DATA, "SP500-Daily-OHLC-1-3-2014-to-12-31-2024.jld2")); # a one-line function definition: joinpath builds the full path of the file, and _jld2 reads it

"""
    MyStringDecodeChallengeDataset() -> NamedTuple

Load the three text files of the String Decode Challenge: two test files and one production file.

The function reads `test_part_1.txt`, `test_part_2.txt`, and `production.txt` from `code/src/data`,
one line at a time, with `_puzzleparse`. These three files are not included in this repository,
so this call stops with an error here.

### Returns
- `NamedTuple`: a tuple with three named fields, each a `Vector{String}` that holds one file's
  lines with the whitespace at both ends removed:
    - `test_part_1`: the lines of `test_part_1.txt`;
    - `test_part_2`: the lines of `test_part_2.txt`;
    - `production`: the lines of `production.txt`.
"""
function MyStringDecodeChallengeDataset()::NamedTuple

    # load three datasets: read each text file from the data folder into a vector of lines.
    # joinpath(folder, name) builds the full path of a file -
    test_part_1 = _puzzleparse(joinpath(_PATH_TO_DATA, "test_part_1.txt"));
    test_part_2 = _puzzleparse(joinpath(_PATH_TO_DATA, "test_part_2.txt"));
    production_data = _puzzleparse(joinpath(_PATH_TO_DATA, "production.txt"));

    # package into a NamedTuple, so we can write, for example, data_tuple.production -
    data_tuple = (
        test_part_1 = test_part_1,
        test_part_2 = test_part_2,
        production = production_data
    );

    # return the NamedTuple -
    return data_tuple;
end

"""
    MyCommonSurnameDataset() -> DataFrame

Load the common surnames of each country as a DataFrame.

The function reads the file `common-surnames-by-country.csv` from `code/src/data`. This file is not
included in this repository, so this call stops with an error here. The original dataset is at
[Common Surnames by Country](https://github.com/sigpwned/popular-names-by-country-dataset).

### Returns
- `DataFrame`: one row per line of the CSV file, with the column names of its first line.
"""
function MyCommonSurnameDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "common-surnames-by-country.csv"), DataFrame) # CSV.read reads the comma-separated file; the second argument, DataFrame, says to return a DataFrame
end

"""
    MyCommonForenameDataset() -> DataFrame

Load the common first names (forenames) of each country as a DataFrame.

The function reads the file `common-forenames-by-country.csv` from `code/src/data`. This file is not
included in this repository, so this call stops with an error here. The original dataset is at
[Common Forenames by Country](https://github.com/sigpwned/popular-names-by-country-dataset).

### Returns
- `DataFrame`: one row per line of the CSV file, with the column names of its first line.
"""
function MyCommonForenameDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "common-forenames-by-country.csv"), DataFrame) # CSV.read reads the comma-separated file; the second argument, DataFrame, says to return a DataFrame
end


"""
    MyKaggleHousingPricesDataset() -> DataFrame

Load the house prices dataset from Kaggle as a DataFrame. The week-07 L7d lab fits a price model to
it by ordinary least squares, and the week-08 L8d lab uses it for cross-validation and residual
checks.

The function reads the file `Housing-Training-Dataset-Kaggle.csv` from `code/src/data`. The
original dataset is at
[Housing Prices Dataset on Kaggle](https://www.kaggle.com/datasets/yasserh/housing-prices-dataset?select=Housing.csv).

### Returns
- `DataFrame`: 545 rows, one per house, and 13 columns: `price`, `area`, `bedrooms`, `bathrooms`,
  `stories`, `mainroad`, `guestroom`, `basement`, `hotwaterheating`, `airconditioning`, `parking`,
  `prefarea`, and `furnishingstatus`. The columns `mainroad` through `airconditioning`, and
  `prefarea`, hold the text `"yes"` or `"no"`. The column `furnishingstatus` holds `"furnished"`,
  `"semi-furnished"`, or `"unfurnished"`. The other columns hold numbers.
"""
function MyKaggleHousingPricesDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "Housing-Training-Dataset-Kaggle.csv"), DataFrame) # CSV.read reads the comma-separated file; the second argument, DataFrame, says to return a DataFrame
end

"""
    MyBanknoteAuthenticationDataset() -> DataFrame

Load the [banknote authentication dataset from the UCI archive](https://archive.ics.uci.edu/dataset/267/banknote+authentication)
as a DataFrame. Each row describes one banknote, genuine or forged, by four numbers computed from a
camera image of the note. The week-09 L9a example trains a Perceptron on this data, and the week-09
L9d lab trains a logistic regression model on it.

The function reads the file `data-banknote-authentication.csv` from `code/src/data`.

### Returns
- `DataFrame`: 1372 rows, one per banknote, and 5 columns. The four columns `variance`, `skewness`,
  `curtosis`, and `entropy` hold the image features, as decimal numbers. The column `class` holds
  the label, the integer `-1` or `1`.
"""
function MyBanknoteAuthenticationDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "data-banknote-authentication.csv"), DataFrame) # CSV.read reads the comma-separated file; the second argument, DataFrame, says to return a DataFrame
end

"""
    MyEnglishLanguageVocabularyModel() -> Dict{Char, Set{String}}

Load about 370,000 English words, and group them by their first letter. The week-11 L11b lab uses
the groups to estimate how often each letter follows the first letter of a word.

The function reads the file `words_dictionary.json` from `code/src/data`. The file holds one JSON
object whose keys are the words, from the
[english-words collection](https://github.com/dwyl/english-words). In this file, the first letter
of every word is one of the lowercase letters `'a'` to `'z'`.

### Returns
- `Dict{Char, Set{String}}`: the words grouped by first letter. Each key is a letter, a `Char`, and
  its value is the set of words that start with that letter. A `Set` holds each word once, in no
  particular order.
"""
function MyEnglishLanguageVocabularyModel()::Dict{Char, Set{String}}

    # initialize -
    filepath = joinpath(_PATH_TO_DATA, "words_dictionary.json"); # the full path of the word file
    data = JSON.parsefile(filepath); # read the data from the *.json file into a dictionary whose keys are the words
    wordsdictionary = Dict{Char, Set{String}}(); # create an empty dictionary: first letter => set of words

    # the words are the keys of the dictionary. keys(data) gives the keys, and |> passes them to
    # collect, which copies them into a vector -
    list_of_words = keys(data) |> collect;
    for word ∈ list_of_words

        # what is the first letter of the word?
        first_letter = word[1]; # this gives the first letter of the word as a Char (one character, written with single quotes)

        # do we have this letter in the model? If not, we add an empty set for it -
        if (haskey(wordsdictionary, first_letter) == false)
            wordsdictionary[first_letter] = Set{String}(); # create an empty new set
        end

        # add the word to the set of its first letter -
        push!(wordsdictionary[first_letter], word); # wordsdictionary[first_letter] is the set itself, so push! adds the word to the set stored in the dictionary
    end

    # return the words grouped by first letter -
    return wordsdictionary;
end

"""
    MyGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char = '#',
        delim::Char = ',') -> Dict{Int64,MyGraphEdgeModel}

Read an edge-list file, and return one edge model per edge. The week-04 L4b and L4d labs use this
function to load a graph from a file.

An edge-list file has one edge per line, such as `3,4,8` for an edge from vertex 3 to vertex 4 with
weight 8. We read the file one line at a time. We skip every empty line, and every line that
contains the `comment` character anywhere, not only at the start. We pass each remaining line to
the function `edgeparser`, and store the result as an edge model. The caller supplies
`edgeparser`; the L4b and L4d labs define it in the notebook.

### Arguments
- `filepath::String`: the full path of the edge-list file.
- `edgeparser::Function`: a function `edgeparser(line, delim)` that takes one line of the file and
  the delimiter character, and returns a tuple `(source, target, data)`, where:
  - `source::Int64`: the vertex the edge starts from;
  - `target::Int64`: the vertex the edge ends at;
  - `data`: anything else we want to store with the edge, such as a weight; we store it in the
    `weight` field.
- `comment::Char = '#'`: we skip every line that contains this character.
- `delim::Char = ','`: the character that separates the fields of a line; we pass it to
  `edgeparser`.

### Returns
- `Dict{Int64,MyGraphEdgeModel}`: the edges. The keys are `0, 1, 2, …` in file order, counting only
  the lines we pass to `edgeparser`. Each edge model has the fields `id` (the same number as its
  key), `source`, `target`, and `weight`.

### Throws
- an `ArgumentError` if `filepath` is not the path of an existing file.
- any error that `edgeparser` throws for a line it cannot read.
"""
function MyGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char='#',
    delim::Char=',')::Dict{Int64,MyGraphEdgeModel}

    # quick validation - ensure the path exists and is a regular file -
    if !isfile(filepath) # ! means "not": we enter the if-block when isfile(filepath) is false
        throw(ArgumentError("Invalid filepath: '$filepath' does not point to an existing regular file"))
    end

    # initialize: an empty dictionary of edges, and the counter that numbers them -
    edges = Dict{Int64, MyGraphEdgeModel}()
    linecounter = 0; # the id of the next edge; the first edge gets id 0

    # main loop. The do block opens the file, names the open file `file`, runs the block, and
    # closes the file when the block ends, even if an error occurs -
    open(filepath, "r") do file # open a stream to the file
        for line ∈ eachline(file) # process each line in a file, one at a time

            # check: is this a comment line or an empty line? If so, skip it -
            if (contains(line, comment) == true) || (isempty(line) == true) # || means "or": true when either test is true
                continue; # skip this line, and move to the next one
            end

            # call the edge parser function, and unpack the tuple it returns into s, t, and data -
            (s,t,data) = edgeparser(line, delim);

            # build the edge model from a NamedTuple of its fields (build is in Factory.jl), and
            # store it under the key linecounter -
            edges[linecounter] = build(MyGraphEdgeModel, (
                source = s,
                target = t,
                weight = data,
                id = linecounter
            ));

            # update the line counter -
            linecounter += 1; # linecounter += 1 means linecounter = linecounter + 1
        end
    end

    # return the dictionary of edges -
    return edges;
end

"""
    MyConstrainedGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char = '#',
        delim::Char = ',') -> Dict{Int64,MyConstrainedGraphEdgeModel}

Read an edge-list file for a flow network, and return one edge model per edge. Each edge carries a
weight, such as a cost, and a lower and upper bound on the flow along the edge. The week-05 L5a
worked example (through `build_flow_graph` in FlowValidation.jl) and the week-05 L5b lab use this
function.

An edge-list file has one edge per line, such as `1,2,1,0,1` for an edge from vertex 1 to vertex 2
with cost 1, lower bound 0, and upper bound 1. We read the file one line at a time.
We skip every empty line, and every line that contains the `comment` character anywhere, not only
at the start. We pass each remaining line to the function `edgeparser`, and store the result as an
edge model.

### Arguments
- `filepath::String`: the full path of the edge-list file.
- `edgeparser::Function`: a function `edgeparser(line, delim)` that takes one line of the file and
  the delimiter character, and returns a tuple `(source, target, weight, lower, upper)`, where:
  - `source::Int64`: the vertex the edge starts from;
  - `target::Int64`: the vertex the edge ends at;
  - `weight::Union{Nothing, Number}`: the weight of the edge, such as a cost per unit of flow, or
    `nothing`;
  - `lower::Union{Nothing, Number}`: the smallest flow allowed along the edge, or `nothing`;
  - `upper::Union{Nothing, Number}`: the largest flow allowed along the edge (its capacity), or
    `nothing`.
- `comment::Char = '#'`: we skip every line that contains this character.
- `delim::Char = ','`: the character that separates the fields of a line; we pass it to
  `edgeparser`.

### Returns
- `Dict{Int64,MyConstrainedGraphEdgeModel}`: the edges. The keys are `0, 1, 2, …` in file order,
  counting only the lines we pass to `edgeparser`. Each edge model has the fields `id` (the same
  number as its key), `source`, `target`, `weight`, `lower`, and `upper`.

### Throws
- an `ArgumentError` if `filepath` is not the path of an existing file.
- any error that `edgeparser` throws for a line it cannot read.
"""
function MyConstrainedGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char='#',
    delim::Char=',')::Dict{Int64,MyConstrainedGraphEdgeModel}


    # quick validation - ensure the path exists and is a regular file -
    if !isfile(filepath) # ! means "not": we enter the if-block when isfile(filepath) is false
        throw(ArgumentError("Invalid filepath: '$filepath' does not point to an existing regular file"))
    end

    # initialize: an empty dictionary of edges, and the counter that numbers them -
    edges = Dict{Int64, MyConstrainedGraphEdgeModel}()
    linecounter = 0; # the id of the next edge; the first edge gets id 0

    # main loop. The do block opens the file, names the open file `file`, runs the block, and
    # closes the file when the block ends, even if an error occurs -
    open(filepath, "r") do file # open a stream to the file
        for line ∈ eachline(file) # process each line in a file, one at a time

            # check: is this a comment line or an empty line? If so, skip it -
            if (contains(line, comment) == true) || (isempty(line) == true) # || means "or": true when either test is true
                continue; # skip this line, and move to the next one
            end

            # call the edge parser function, and unpack the tuple it returns into s, t, w, l, and u -
            (s,t,w,l,u) = edgeparser(line, delim);

            # build the edge model from a NamedTuple of its fields (build is in Factory.jl), and
            # store it under the key linecounter -
            edges[linecounter] = build(MyConstrainedGraphEdgeModel, (
                source = s,
                target = t,
                weight = w,
                lower = l,
                upper = u,
                id = linecounter
            ));

            # update the line counter -
            linecounter += 1; # linecounter += 1 means linecounter = linecounter + 1
        end
    end

    # return the dictionary of edges -
    return edges;
end

"""
    MyMNISTHandwrittenDigitImageDataset(; number_of_examples::Int64 = 1000)
        -> Dict{Int64, Array{Gray{N0f8},3}}

Load grayscale images of the handwritten digits 0 to 9. Each image is 28 × 28 pixels. The images
were taken from the [MNIST dataset](https://www.kaggle.com/datasets/hojjatk/mnist-dataset).

The function reads the folder `images-mnist-digits` in `code/src/data`, which holds one subfolder
per digit, named `0` to `9`. From each subfolder it reads the first `number_of_examples` files,
sorted by name, and loads each `.jpg` file. This folder is not included in
this repository, so this call stops with an error here.

### Arguments
- `number_of_examples::Int64 = 1000`: the number of files to read for each digit. This is a keyword
  argument: write `MyMNISTHandwrittenDigitImageDataset(number_of_examples = 500)`.

### Returns
- `Dict{Int64, Array{Gray{N0f8},3}}`: the images, by digit. Each key is a digit `0` to `9`, and its
  value is a `28 × 28 × number_of_examples` array: image `k` of digit `d` is `data[d][:,:,k]`. Each
  pixel is a `Gray{N0f8}`, a gray level between 0 (black) and 1 (white) stored in 8 bits. If one of
  the files read is not a `.jpg` file, its slice of the array is never set and holds arbitrary
  values.

### Throws
- an error if a digit's subfolder holds fewer than `number_of_examples` files.
"""
function MyMNISTHandwrittenDigitImageDataset(; number_of_examples::Int64 = 1000)::Dict{Int64, Array{Gray{N0f8},3}}

    # initailize -
    number_of_rows = 28; # the height of each image, in pixels
    number_of_cols = 28; # the width of each image, in pixels
    number_digit_array = range(0, stop=9, step=1) |> collect; # the digits 0, 1, ..., 9: range describes them, and |> passes the range to collect, which makes a vector
    pathtoimages = joinpath(_PATH_TO_DATA, "images-mnist-digits"); # the folder that holds one subfolder per digit
    training_image_dictionary = Dict{Int64, Array{Gray{N0f8},3}}(); # digit => array of its images

    # main loop: one digit each pass -
    for i ∈ number_digit_array

        # create the array for this digit, and list the files in its subfolder -
        image_digit_array = Array{Gray{N0f8},3}(undef, number_of_rows, number_of_cols, number_of_examples); # a 28 × 28 × number_of_examples array; undef means the entries are not set yet
        files = readdir(joinpath(pathtoimages, "$(i)")); # the file names in subfolder i, sorted by name; "$(i)" is the digit as text
        imagecount = 1; # counts the images loaded; this counter is not used after the loop

        # load the first number_of_examples files, keeping only the .jpg images -
        for fileindex ∈ 1:number_of_examples
            filename = files[fileindex];
            ext = _file_extension(filename) # the text after the last period, such as "jpg"
            if (ext == "jpg")
                image_digit_array[:,:,fileindex] = joinpath(pathtoimages, "$(i)", filename) |> x-> FileIO.load(x); # build the full path of the image, then pass it to the anonymous function x -> FileIO.load(x), which reads the image; we store it as slice fileindex of the array
                imagecount += 1
            end
        end

        # capture: store the images of digit i under the key i -
        training_image_dictionary[i] = image_digit_array
    end

    # return the images, by digit -
    return training_image_dictionary;
end
# -- PUBLIC FUNCTIONS ABOVE HERE ------------------------------------------------------------------------------ #
