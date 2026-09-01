const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-03"))

include(joinpath(WEEK_ROOT, "L3b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L3c", "Include.jl"))

# The L3d lab ships a deliberately incomplete student bubble sort. Validation
# loads the reference solution directly instead of the lab's Include.jl, which
# would load the student module of the same name.
include(joinpath(WEEK_ROOT, "L3d", "src", "Compute-solution.jl"))
using .L3dSorting

@testset "L3b stacks and queues" begin
    # Verify the LIFO discipline through the public MyStack interface.
    stack = MyStack{Int64}()
    @test isempty(stack)
    push!(stack, 1)
    push!(stack, 2)
    push!(stack, 3)
    @test length(stack) == 3
    @test peek(stack) == 3
    @test pop!(stack) == 3
    @test pop!(stack) == 2
    @test pop!(stack) == 1
    @test isempty(stack)

    # Verify the FIFO discipline through the public MyQueue interface.
    queue = MyQueue{String}()
    push!(queue, "a")
    push!(queue, "b")
    push!(queue, "c")
    @test length(queue) == 3
    @test peek(queue) == "a"
    @test popfirst!(queue) == "a"
    @test popfirst!(queue) == "b"
    @test popfirst!(queue) == "c"
    @test isempty(queue)

    # Verify the balanced-delimiter checker, including every failure mode.
    @test isbalanced("f(x[2]) + {a: (b)}")
    @test isbalanced("no delimiters at all")
    @test isbalanced("")
    @test !isbalanced("f(x[2)]")
    @test !isbalanced(")(")
    @test !isbalanced("open( forever")
end

@testset "L3c iteration and recursion" begin
    @test fibonacci(Int64(10))[10] == 55
    recursive_series = Dict{Int64, Int64}()
    memoized_series = Dict{Int64, Int64}()
    @test fibonacci!(Int64(10), recursive_series) == 55
    @test memoization_fibonacci!(Int64(50), memoized_series) == 12_586_269_025
    @test recursive_series[0] == 0
    @test memoized_series[25] == 75_025
    @test iterative_fibonacci_report(0) == (value = Int64(0), additions = 0)
    @test iterative_fibonacci_report(10) == (value = Int64(55), additions = 9)
    @test recursive_fibonacci_report(0) == (value = Int64(0), calls = 1)
    @test recursive_fibonacci_report(10) == (value = Int64(55), calls = 177)
    @test recursive_fibonacci_report(15).value == iterative_fibonacci_report(15).value
    @test recursive_fibonacci_report(15).calls > iterative_fibonacci_report(15).additions
    @test_throws ArgumentError recursive_fibonacci_report(-1)
    @test_throws ArgumentError recursive_fibonacci_report(41)
    @test_throws ArgumentError iterative_fibonacci_report(true)
end

@testset "L3d sorting contracts" begin
    values = [5, 1, 4, 2, 8, 2]
    @test bubblesort(values) == sort(values)
    @test values == [5, 1, 4, 2, 8, 2] # the non-mutating wrapper sorts a copy
    in_place = [3, 1, 2]
    @test bubblesort!(in_place) == [1, 2, 3]
    @test in_place == [1, 2, 3] # the mutating version sorts its argument
    @test bubblesort(Int[]) == Int[]
    @test bubblesort([7]) == [7]
    @test bubblesort(collect(10:-1:1)) == collect(1:10)
    @test quicksort(values) == sort(values)
    report = bubble_sort_report(values)
    @test report.values == sort(values)
    @test values == [5, 1, 4, 2, 8, 2]
    @test report.comparisons > 0
    @test report.swaps > 0
    @test bubble_sort_report(Int[]).values == Int[]
    @test bubble_sort_report([1, 2, 3]).swaps == 0
    @test sort(report.values) == sort(values)

    for sample in (Int[], [1], values, [3, 3, 1], collect(10:-1:1))
        snapshot = copy(sample)
        @test quicksort_reference(sample) == sort(sample)
        @test sample == snapshot
    end
    @test bubble_sort_report(["bbb", "a", "cc"]; lt = (a, b) -> length(a) < length(b)).values ==
          ["a", "cc", "bbb"]
end

@testset "L3d sound library" begin
    library = load_sound_library(joinpath(WEEK_ROOT, "L3d", "sounds"))
    @test length(library) == 128
    @test all(haskey(library, index) for index in 1:128)
    waveform, sampling_frequency = library[1]
    @test waveform isa Matrix{Float64}
    @test sampling_frequency > 0
end

@testset "L3d lab ships an incomplete student bubble sort" begin
    stub = read(joinpath(WEEK_ROOT, "L3d", "src", "Compute.jl"), String)
    @test occursin("TODO 1", stub)
    @test occursin("TODO 2", stub)
    @test occursin("TODO 3", stub)
    @test occursin("Complete TODO 1 through TODO 3", stub)
    @test occursin("not implemented yet", stub)
    # The distinctive solution expression must be absent from the student stub.
    @test !occursin("values[position], values[position + 1]", stub)

    # The stub must also parse and actually throw when called. Loading it into a
    # sandbox module leaves the reference solution loaded above untouched.
    sandbox = Module(:L3dStubSandbox)
    Base.include(sandbox, joinpath(WEEK_ROOT, "L3d", "src", "Compute.jl"))
    @test_throws ErrorException sandbox.L3dSorting.bubblesort!([3, 1, 2])
    @test_throws ErrorException sandbox.L3dSorting.bubblesort([3, 1, 2])
end
