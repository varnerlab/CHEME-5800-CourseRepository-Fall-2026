import Base.+

"""
    +(buffer::Array{String,1}, line::String)

Extend `Base.+` to append a `String` to a `String` array in-place.
This allows using `+(buffer, line)` as a concise alternative to `push!(buffer, line)`.

### Arguments
- `buffer::Array{String,1}`: the string array to append to.
- `line::String`: the string to append.

### Returns
Return the same, mutated `buffer`, as with `push!`.
"""
function +(buffer::Array{String,1}, line::String)
    push!(buffer, line)
end

"""
    read_reaction_file(path_to_file::String) -> Array{String,1}

Read VFF reaction records, preserving file order. Discard empty lines and any
line containing `//` anywhere; inline comments cause the whole record to be
excluded. Whitespace-only lines are not filtered and other whitespace is retained.
Each record is `name,reactants,products,is_reversible`; species on either side
are separated by `+`, optional coefficients use `coefficient*species`, and
`[]` or `∅` denotes the surroundings. This reader does not validate the records.
File-access errors propagate to the caller.

### Arguments
- `path_to_file::String`: the path to the VFF reaction file.

### Returns
- `Array{String,1}`: an array of records as strings.
"""
function read_reaction_file(path_to_file::String)::Array{String,1}

    # initialize -
    vff_file_buffer = String[]
    vff_reaction_array = Array{String,1}()

    # Read in the file -
    open("$(path_to_file)", "r") do file
        for line in eachline(file)
            +(vff_file_buffer, line)
        end
    end

    # process -
    for reaction_line ∈ vff_file_buffer
        
        # skip comments and empty lines -
        if (occursin("//", reaction_line) == false && 
            isempty(reaction_line) == false)
        
            # grab -
            push!(vff_reaction_array,reaction_line)
        end
    end

    # return -
    return vff_reaction_array
end