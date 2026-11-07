# ------------------------------------------------------------------------------------------------ #
# TextRepresentation.jl
#
# Code-point formatting helper used by the week-02 L2c lecture on text representation.
#
# Every character has a number in the Unicode standard, called its code point. Unicode tables
# write the code point in base 16 (hexadecimal) after the prefix U+, for example U+0041 for 'A'.
# The L2c lecture computes this notation by hand, by repeated division by 16, and then compares
# its answer with the function in this file.
#
# Public function:
#   codepoint_hex(...)   returns the code point of a character in U+XXXX notation, as a String
# ------------------------------------------------------------------------------------------------ #

"""
    codepoint_hex(character::Char) -> String

Return the Unicode code point of a character in the standard `U+XXXX` notation.

Unicode gives every character a number, its code point. The standard notation writes this number
in base 16 (hexadecimal) with the digits `0`-`9` and the uppercase letters `A`-`F`, puts the prefix
`U+` in front, and uses at least four digits. We add zeros on the left of a code point that has
fewer than four hexadecimal digits, so `'A'` (code point 65) becomes `U+0041`. A code point above
`U+FFFF` keeps all five or six digits it needs.

### Arguments
- `character::Char`: one character, written with single quotes, such as `'A'` or `'é'`.

### Returns
- `String`: the code point in `U+XXXX` notation, such as `"U+0041"`.

### Example
```julia
codepoint_hex('A')   # returns "U+0041"
codepoint_hex('é')   # returns "U+00E9"
codepoint_hex('😀')  # returns "U+1F600"
```
"""
function codepoint_hex(character::Char)::String

    # convert the character to hexadecimal text, in three nested steps read from the inside out -
    #   1. UInt32(character) gives the code point as a number (an unsigned 32-bit integer);
    #   2. string(...; base = 16, pad = 4) writes that number in base 16 with at least four digits,
    #      adding zeros on the left when needed (the arguments after the ; are keyword arguments);
    #   3. uppercase(...) turns the letters a-f into A-F, as in Unicode tables.
    hexadecimal = uppercase(string(UInt32(character); base = 16, pad = 4))

    # add the U+ prefix and return the result. In a string, $(hexadecimal) inserts the value of
    # the variable hexadecimal (this is called string interpolation) -
    return "U+$(hexadecimal)"
end
