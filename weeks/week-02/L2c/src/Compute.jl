module L2cTextRepresentation

export codepoint_hex

"""
    codepoint_hex(character::Char) -> String

Return a character's Unicode code point in uppercase `U+XXXX` notation. Code
points above `U+FFFF` use the additional hexadecimal digits they require.
"""
function codepoint_hex(character::Char)::String
    # Convert the numerical code point to hexadecimal and pad values below
    # U+1000 to the four digits required by standard Unicode notation.
    hexadecimal = uppercase(string(UInt32(character); base = 16, pad = 4))

    # Add the U+ prefix used in Unicode character tables and documentation.
    return "U+$(hexadecimal)"
end

end
