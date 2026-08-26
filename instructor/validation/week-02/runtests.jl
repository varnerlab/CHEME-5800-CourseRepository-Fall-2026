include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2a", "Include.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02", "L2c", "Include.jl"))

# L2b and L2d ship deliberately incomplete student functions. Validation loads
# the reference solutions directly instead of loading each lab's Include.jl,
# which would load the student module with the same name.
const WEEK02 = joinpath(@__DIR__, "..", "..", "..", "weeks", "week-02")
include(joinpath(WEEK02, "L2b", "src", "Compute-solution.jl"))
include(joinpath(WEEK02, "L2d", "src", "Compute-solution.jl"))
using .L2bFibonacci
using .L2dUnicodeTable

@testset "Week 2 defensive Fibonacci interface" begin
    # Verify supported inputs and the Int64 boundary.
    @test fibonacci_sequence(0) == [0]
    @test fibonacci_sequence(1) == [0, 1]
    @test fibonacci_sequence(10) == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
    @test last(fibonacci_sequence(92)) == 7_540_113_804_746_346_429

    # Verify every invalid-input category in the public interface.
    @test_throws ArgumentError fibonacci_sequence(-1)
    @test_throws ArgumentError fibonacci_sequence(93)
    @test_throws ArgumentError fibonacci_sequence(3.5)
    @test_throws ArgumentError fibonacci_sequence(true)
end

@testset "Week 2 text representation" begin
    # Verify the Unicode formatter used by the L2c lecture.
    @test codepoint_hex('A') == "U+0041"
    @test codepoint_hex('Δ') == "U+0394"
    @test codepoint_hex('🍣') == "U+1F363"
end

@testset "Week 2 Unicode character table" begin
    # Verify the complete table schema and ASCII behavior.
    ascii_table = character_table("P101")
    @test names(ascii_table) == [
        "position",
        "character",
        "decimal_codepoint",
        "unicode_codepoint",
        "utf8_byte_count",
    ]
    @test ascii_table.position == [1, 2, 3, 4]
    @test ascii_table.character == ['P', '1', '0', '1']
    @test ascii_table.utf8_byte_count == [1, 1, 1, 1]

    # Verify code points and byte counts for non-ASCII technical symbols.
    unicode_table = character_table("ΔP °C")
    @test unicode_table.character == ['Δ', 'P', ' ', '°', 'C']
    @test unicode_table.decimal_codepoint[[1, 4]] == [916, 176]
    @test unicode_table.unicode_codepoint[[1, 4]] == ["U+0394", "U+00B0"]
    @test unicode_table.utf8_byte_count == [2, 1, 1, 2, 1]

    # Verify that the empty result retains its documented typed schema.
    empty_table = character_table("")
    @test nrow(empty_table) == 0
    @test eltype(empty_table.character) == Char
    @test eltype(empty_table.unicode_codepoint) == String

    # Verify the documented error for a non-string input.
    @test_throws ArgumentError character_table(42)
end

@testset "Week 2 labs ship incomplete student functions" begin
    # Each distinctive solution expression must be absent from the student stub.
    for (lab, leaked_expression) in (
        ("L2b", "sequence[position] = Base.Checked.checked_add"),
        ("L2d", "push!(table, ("),
    )
        stub = read(joinpath(WEEK02, lab, "src", "Compute.jl"), String)
        @test occursin("TODO 1", stub)
        @test occursin("TODO 2", stub)
        @test occursin("TODO 3", stub)
        @test occursin("Complete TODO 1 through TODO 3", stub)
        @test occursin("not implemented yet", stub)
        @test !occursin(leaked_expression, stub)
    end
end
