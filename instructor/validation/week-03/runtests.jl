const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-03"))

include(joinpath(WEEK_ROOT, "L3b", "Include.jl"))
include(joinpath(WEEK_ROOT, "L3c", "Include.jl"))
include(joinpath(WEEK_ROOT, "L3d", "Include.jl"))

@testset "L3b data validation and provenance" begin
    data_root = joinpath(WEEK_ROOT, "L3b", "data")
    csv_path = joinpath(data_root, "reactor-runs.csv")
    metadata_path = joinpath(data_root, "reactor-metadata.json")
    bundle = load_reactor_bundle(csv_path, metadata_path)
    @test bundle.validation.valid
    @test isempty(bundle.validation.errors)
    @test nrow(bundle.runs) == 8
    @test occursin("synthetic", lowercase(bundle.metadata["provenance"]))
    @test length(file_sha256(csv_path)) == 64

    invalid = CSV.read(joinpath(data_root, "reactor-runs-invalid-example.csv"), DataFrame)
    report = validate_reactor_runs(invalid)
    @test !report.valid
    @test any(error -> occursin("residence_time_min", error), report.errors)
    @test any(error -> occursin("conversion_fraction", error), report.errors)

    @test !validate_reactor_runs(select(bundle.runs, Not(:catalyst))).valid
    @test !validate_reactor_runs(bundle.runs[1:0, :]).valid
    duplicates = vcat(bundle.runs, bundle.runs[1:1, :])
    @test any(error -> occursin("unique", error), validate_reactor_runs(duplicates).errors)
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
