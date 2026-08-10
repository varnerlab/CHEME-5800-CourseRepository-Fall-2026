# -- PRIVATE FUNCTIONS BELOW HERE ------------------------------------------------------------------------------ #
function _puzzleparse(filepath::String)::Vector{String}

    # initialize -
    result = Vector{String}();

    open(filepath, "r") do io
        for line ∈ eachline(io)
            push!(result, strip(line)); # cutoff whitespace
        end
    end
    return result;
end

function _jld2(path::String)::Dict{String,Any}
    return load(path);
end

_file_extension(file::String) = file[findlast(==('.'), file)+1:end]; # helper function to get the file extension

# -- PRIVATE FUNCTIONS ABOVE HERE ------------------------------------------------------------------------------ #

# -- PUBLIC FUNCTIONS BELOW HERE ------------------------------------------------------------------------------- #

"""
    MyTrainingMarketDataSet() -> Dict{String, DataFrame}

Load the components of the SP500 Daily open, high, low, close (OHLC) dataset as a dictionary of DataFrames.
This data was provided by [Polygon.io](https://polygon.io/) and covers the period from January 3, 2014, to December 31, 2024.

"""
MyTrainingMarketDataSet() = _jld2(joinpath(_PATH_TO_DATA, "SP500-Daily-OHLC-1-3-2014-to-12-31-2024.jld2"));

"""
    MyStringDecodeChallengeDataset() -> NamedTuple

Load the String Decode Challenge testing and production datasets.

### Return
- `NamedTuple`: A tuple containing the three datasets:
    - `test_part_1`: The first part of the test dataset.
    - `test_part_2`: The second part of the test dataset.
    - `production`: The production dataset.
"""
function MyStringDecodeChallengeDataset()::NamedTuple

    # load three datasets -
    test_part_1 = _puzzleparse(joinpath(_PATH_TO_DATA, "test_part_1.txt"));
    test_part_2 = _puzzleparse(joinpath(_PATH_TO_DATA, "test_part_2.txt"));
    production_data = _puzzleparse(joinpath(_PATH_TO_DATA, "production.txt"));

    # package into a NamedTuple -
    data_tuple = (
        test_part_1 = test_part_1,
        test_part_2 = test_part_2,
        production = production_data
    );

    return data_tuple;
end

"""
    MyCommonSurnameDataset() -> DataFrame
Load the common surnames dataset by country as a DataFrame.
The original dataset can be found at: [Common Surnames by Country](https://github.com/sigpwned/popular-names-by-country-dataset).
"""
function MyCommonSurnameDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "common-surnames-by-country.csv"), DataFrame)
end

"""
    MyCommonForenameDataset() -> DataFrame
Load the common forenames dataset by country as a DataFrame.
The original dataset can be found at: [Common Forenames by Country](https://github.com/sigpwned/popular-names-by-country-dataset).
"""
function MyCommonForenameDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "common-forenames-by-country.csv"), DataFrame)
end


"""
    MyHousingPricesDataset() -> DataFrame

Load the house prices dataset from Kaggle as a DataFrame.
The original dataset can be found at: [Housing Prices Dataset on Kaggle](https://www.kaggle.com/datasets/yasserh/housing-prices-dataset?select=Housing.csv)
"""
function MyKaggleHousingPricesDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "Housing-Training-Dataset-Kaggle.csv"), DataFrame)
end

"""
    MyBanknoteAuthenticationDataset() -> DataFrame

The second dataset we will explore is the [banknote authentication dataset from the UCI archive](https://archive.ics.uci.edu/dataset/267/banknote+authentication).
This dataset has `1372` instances of 4 continuous features and an integer (-1,1) class variable.
"""
function MyBanknoteAuthenticationDataset()::DataFrame
    return CSV.read(joinpath(_PATH_TO_DATA, "data-banknote-authentication.csv"), DataFrame)
end

"""
    MyEnglishLanguageVocabularyModel() -> Dict{Char, Set{String}}

Load the English language vocabulary model as a dictionary where the keys are characters (the first letter of each word)
and the values are sets of words that start with that letter.
"""
function MyEnglishLanguageVocabularyModel()::Dict{Char, Set{String}}

    # initialize -
    filepath = joinpath(_PATH_TO_DATA, "words_dictionary.json");
    data = JSON.parsefile(filepath); # read the data from the *.json file
    wordsdictionary = Dict{Char, Set{String}}(); # create an empty dictionary

    # the words are the keys of the dictionary
    list_of_words = keys(data) |> collect;
    for word ∈ list_of_words

        # what is the first letter of the word?
        first_letter = word[1]; # this gives the first letter of the word as a Char

        # do we have this letter in the model?
        if (haskey(wordsdictionary, first_letter) == false)
            wordsdictionary[first_letter] = Set{String}(); # create an empty new set
        end

        # add the word to the set
        push!(wordsdictionary[first_letter], word); # fancy!!
    end

    return wordsdictionary;
end

"""
    function MyGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char='#',
    delim::Char=',')::Dict{Int64,MyGraphEdgeModel}

Function to parse an edge file and return a dictionary of edges models.

### Arguments
- `filepath::String`: The path to the edge file.
- `edgeparser::Function`: A callback function to parse each edge line. This function should take a line as input, and a delimiter character, and return a tuple of the form `(source, target, data)`, where:
  - `source::Int64`: The source node ID.
  - `target::Int64`: The target node ID.
  - `data::Any`: Any additional data associated with the edge, e.g., a weight, a tuple of information, etc.

### Returns
- `Dict{Int64,MyGraphEdgeModel}`: A dictionary of edge models.
"""
function MyGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char='#',
    delim::Char=',')::Dict{Int64,MyGraphEdgeModel}

    # quick validation - ensure the path exists and is a regular file
    if !isfile(filepath)
        throw(ArgumentError("Invalid filepath: '$filepath' does not point to an existing regular file"))
    end

    # initialize
    edges = Dict{Int64, MyGraphEdgeModel}()
    linecounter = 0;

    # main -
    open(filepath, "r") do file # open a stream to the file
        for line ∈ eachline(file) # process each line in a file, one at a time

            # check: do we have comments?
            if (contains(line, comment) == true) || (isempty(line) == true)
                continue; # skip this line, and move to the next one
            end

            # # call the edge parser callback function -
            (s,t,data) = edgeparser(line, delim);

            # # build the edge model -
            edges[linecounter] = build(MyGraphEdgeModel, (
                source = s,
                target = t,
                weight = data,
                id = linecounter
            ));

            # update the line counter -
            linecounter += 1;
        end
    end

    # return -
    return edges;
end

"""
    function MyConstrainedGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char='#',
        delim::Char=',') -> Dict{Int64,MyConstrainedGraphEdgeModel}

This function parses a constrained graph edge file and returns a dictionary of constrained graph edge models.

### Arguments
- `filepath::String`: The path to the edge file.
- `edgeparser::Function`: A callback function to parse each edge line. This function should take a line as input, and a delimiter character, and return a tuple of the form `(source, target, weight, lower, upper)`, where:
  - `source::Int64`: The source node ID.
  - `target::Int64`: The target node ID.
  - `weight::Union{Nothing, Number}`: The weight of the edge.
  - `lower::Union{Nothing, Number}`: The lower bound of the edge weight.
  - `upper::Union{Nothing, Number}`: The upper bound of the edge weight.

### Returns
- `Dict{Int64,MyConstrainedGraphEdgeModel}`: A dictionary of constrained graph edge models.
"""
function MyConstrainedGraphEdgeModels(filepath::String, edgeparser::Function; comment::Char='#',
    delim::Char=',')::Dict{Int64,MyConstrainedGraphEdgeModel}


    # quick validation - ensure the path exists and is a regular file
    if !isfile(filepath)
        throw(ArgumentError("Invalid filepath: '$filepath' does not point to an existing regular file"))
    end

    # initialize
    edges = Dict{Int64, MyConstrainedGraphEdgeModel}()
    linecounter = 0;

    # main -
    open(filepath, "r") do file # open a stream to the file
        for line ∈ eachline(file) # process each line in a file, one at a time

            # check: do we have comments?
            if (contains(line, comment) == true) || (isempty(line) == true)
                continue; # skip this line, and move to the next one
            end

            # # call the edge parser callback function -
            (s,t,w,l,u) = edgeparser(line, delim);

            # # build the edge model -
            edges[linecounter] = build(MyConstrainedGraphEdgeModel, (
                source = s,
                target = t,
                weight = w,
                lower = l,
                upper = u,
                id = linecounter
            ));

            # update the line counter -
            linecounter += 1;
        end
    end

    # return -
    return edges;
end

"""
    MyMNISTHandwrittenDigitImageDataset(; number_of_training_examples::Int64 = 1000) -> Dict{Int64, Array{Gray{N0f8},3}}

Load the MNIST digits dataset as a dictionary of grayscale images. This dataset contains images of handwritten digits (0-9), each being 28 x 28 pixel images.
The images were taken from the [MNIST dataset](https://www.kaggle.com/datasets/hojjatk/mnist-dataset).

### Arguments
- `number_of_examples::Int64 = 1000`: The number of training examples to load for each digit (0-9). Default is 1000.

"""
function MyMNISTHandwrittenDigitImageDataset(; number_of_examples::Int64 = 1000)::Dict{Int64, Array{Gray{N0f8},3}}

    # initailize -
    number_of_rows = 28;
    number_of_cols = 28;
    number_digit_array = range(0, stop=9, step=1) |> collect;
    pathtoimages = joinpath(_PATH_TO_DATA, "images-mnist-digits");
    training_image_dictionary = Dict{Int64, Array{Gray{N0f8},3}}();

    # main loop -
    for i ∈ number_digit_array

        # create a set for this digit -
        image_digit_array = Array{Gray{N0f8},3}(undef, number_of_rows, number_of_cols, number_of_examples);
        files = readdir(joinpath(pathtoimages, "$(i)"));
        imagecount = 1;
        for fileindex ∈ 1:number_of_examples
            filename = files[fileindex];
            ext = _file_extension(filename)
            if (ext == "jpg")
                image_digit_array[:,:,fileindex] = joinpath(pathtoimages, "$(i)", filename) |> x-> FileIO.load(x);
                imagecount += 1
            end
        end

        # capture -
        training_image_dictionary[i] = image_digit_array
    end

    return training_image_dictionary;
end
# -- PUBLIC FUNCTIONS ABOVE HERE ------------------------------------------------------------------------------ #
