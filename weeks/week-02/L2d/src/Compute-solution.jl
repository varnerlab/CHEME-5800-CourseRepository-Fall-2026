module L2dUnicodeTable

# Reference solution for L2d. The student-facing Compute.jl file contains the
# same interface with TODO comments in place of the implementation.

import DataFrames: DataFrame

export character_table

"""
    character_table(text::AbstractString) -> DataFrame

Build one table row for each character in `text`.

### Arguments
- `text::AbstractString`: Text to analyze. The empty string is supported and
  returns an empty table with the documented columns.

### Returns
- `DataFrame`: A table with the columns `position`, `character`,
  `decimal_codepoint`, `unicode_codepoint`, and `utf8_byte_count`. Position is
  the character's ordinal position in the text, not a byte index.

### Errors
- `ArgumentError`: The input is not a string.
"""
function character_table(text::AbstractString)::DataFrame

    # check: check for empty string input and return an empty DataFrame with the correct schema
    if (isempty(text) == true)
        
        # Allocate typed columns so the empty-string result has the same schema as
        # every populated result.
        table = DataFrame(
            position = Int[],
            character = Char[],
            decimal_codepoint = Int[],
            unicode_codepoint = String[],
            utf8_byte_count = Int[],
        ); 
        return table; # this returns an empty DataFrame with the correct schema for an empty string input
    end


    # Allocate typed columns so the empty-string result has the same schema as
    # every populated result.
    # table = DataFrame(
    #     position = Int[],
    #     character = Char[],
    #     decimal_codepoint = Int[],
    #     unicode_codepoint = String[],
    #     utf8_byte_count = Int[],
    # ); 
    table = DataFrame(); # this is my style, but the above is more explicit and probably better for a reference solution

    # Iterate over characters directly. The counter from enumerate(...) is the
    # character position; it does not assume that String byte indices are dense.
    for (position, character) ∈ enumerate(text) # enumerate returns (1, first character), (2, second character), ...
        
        # Let's compute the decimal code point of the character. 
        # In Julia, a Char is a Unicode code point, and converting it to Int gives us its decimal value.
        decimal_codepoint = Int(character) # e.g., 'A' -> 65, 'é' -> 233, '😊' -> 128522

        # Format the numerical code point in standard uppercase U+XXXX notation.
        #hexadecimal = uppercase(string(UInt32(character); base = 16, pad = 4)) # Seems complicated - is there another way?
        hexadecimal = uppercase(string(decimal_codepoint; base = 16, pad = 4)) # Ok, less complicated, but still a bit verbose. 
        unicode_codepoint = "U+$(hexadecimal)"

        # Convert this character to a one-character String before counting its
        # UTF-8 code units, which are bytes for a Julia String.
        utf8_byte_count = ncodeunits(string(character))

        # Add one complete character record to the result table.
        push!(table, (
            position = position,
            character = character,
            decimal_codepoint = decimal_codepoint,
            unicode_codepoint = unicode_codepoint,
            utf8_byte_count = utf8_byte_count,
        ))
    end

    return table
end

# Reject non-string inputs with the exception type documented by the interface.
character_table(text) = throw(ArgumentError("text must be a string"))

end
