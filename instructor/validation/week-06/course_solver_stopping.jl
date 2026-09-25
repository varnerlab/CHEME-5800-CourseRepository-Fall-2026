using Test, LinearAlgebra
import VLDataScienceMachineLearningPackage as CourseSolvers

@testset "Course-package iterative solver stopping" begin
    A = [4.0 -1.0; -1.0 3.0]
    b = [1.0, 2.0]
    initial = zeros(2)
    for algorithm in (CourseSolvers.JacobiMethod(), CourseSolvers.GaussSeidelMethod(),
                      CourseSolvers.SuccessiveOverRelaxationMethod())
        @testset "$(nameof(typeof(algorithm)))" begin
            run(A, b, x; kwargs...) = CourseSolvers.solve(A, b, x; algorithm, kwargs...)

            # Neither a satisfactory initial guess nor a zero budget permits an update.
            exact = A \ b
            solved = @test_logs run(A, b, exact; maxiterations=0)
            @test sort(collect(keys(solved))) == [0]
            @test solved[0] == exact
            @test solved[0] !== exact
            no_updates = @test_logs (:warn, r"did not converge within 0 iterations") run(A, b, initial; maxiterations=0)
            @test sort(collect(keys(no_updates))) == [0]
            @test no_updates[0] == initial

            # A failed one-correction run must contain exactly the initial and next iterates.
            capped = @test_logs (:warn, r"did not converge within 1 iterations") run(A, b, initial; maxiterations=1)
            @test sort(collect(keys(capped))) == [0, 1]
            expected = algorithm isa CourseSolvers.JacobiMethod ? [0.25, 2/3] : [0.25, 0.75]
            @test capped[1] ≈ expected

            # Check convergence before the budget: a last permitted correction can succeed.
            diagonal = Matrix(Diagonal([2.0, 4.0]))
            at_limit = @test_logs run(diagonal, [2.0, 8.0], initial; maxiterations=1)
            @test sort(collect(keys(at_limit))) == [0, 1]
            @test at_limit[1] == [1.0, 2.0]
            first_success = @test_logs run(diagonal, [2.0, 8.0], initial)
            @test sort(collect(keys(first_success))) == [0, 1]

            # The final archived vector must be the first to meet tolerance.
            omega = algorithm isa CourseSolvers.SuccessiveOverRelaxationMethod ? 1.2 : 1.0
            archive = @test_logs run(A, b, initial; ϵ=1e-10, ω=omega)
            k = maximum(keys(archive))
            @test sort(collect(keys(archive))) == collect(0:k)
            @test norm(b-A*archive[k]) < 1e-10
            @test all(norm(b-A*archive[j]) >= 1e-10 for j in 0:(k-1))
            @test archive[k] ≈ A \ b
            @test initial == zeros(2)
            @test archive[0] == initial
            @test all(archive[j] !== archive[j+1] for j in 0:(k-1))

            # The existing large-residual guard must also stop before storing a correction.
            guarded = @test_logs (:warn, r"appears to be diverging") run(diagonal, zeros(2), fill(1e11, 2))
            @test sort(collect(keys(guarded))) == [0]
            @test_throws ArgumentError run(A, b, initial; maxiterations=-1)
        end
    end
end
