using Test, LinearAlgebra
import VLDataScienceMachineLearningPackage as OxygenCourseSolvers

@testset "L6d dimensionless oxygen diffusion and reaction" begin
    @testset "Boundary assembly and physical checks" begin
        one = build_tissue_system(1, 2.0; boundary = 0.5)
        @test one.A == fill(8.0, 1, 1)
        @test one.b == [2.0]
        @test (one.A \ one.b) == [0.25]

        four = build_tissue_system(2, 3.0)
        @test four.A ≈ [8.0 -1 -1 0; -1 8 0 -1; -1 0 8 -1; 0 -1 -1 8]
        @test four.b == fill(2.0, 4)
        @test four.A \ four.b ≈ fill(1/3, 4)

        model = build_tissue_system(15, 2.0)
        theta = model.A \ model.b
        field = tissue_field(model, theta)
        @test issymmetric(model.A) && isposdef(model.A)
        @test all(0 .< theta .< 1)
        @test field ≈ reverse(field; dims = 1)
        @test field ≈ reverse(field; dims = 2)
        @test field ≈ transpose(field)
        @test all(field[1, :] .== 1) && all(field[:, end] .== 1)
        @test minimum(field) ≈ field[9, 9]
        @test field[9, 9] ≈ 0.39055684588763656 atol = 1e-10

        # Recover every interior value at its specified coordinate, using an asymmetric field.
        numbered = collect(1.0:225.0)
        numbered_field = tissue_field(model, numbered)
        @test numbered_field[2, 2] == 1
        @test numbered_field[16, 2] == 15
        @test numbered_field[2, 3] == 16

        no_reaction = build_tissue_system(7, 0.0; boundary = 0.7)
        @test no_reaction.A \ no_reaction.b ≈ fill(0.7, 49)
        no_supply = build_tissue_system(7, 2.0; boundary = 0.0)
        @test no_supply.A \ no_supply.b == zeros(49)
        half_supply = build_tissue_system(15, 2.0; boundary = 0.5)
        @test half_supply.A == model.A
        @test half_supply.A \ half_supply.b ≈ theta/2
        larger = build_tissue_system(15, 4.0)
        @test all((larger.A \ larger.b) .< theta)

        # Sum the incoming edge-link fluxes independently of A and b.
        edge_supply = sum(1 .- field[2, 2:16]) + sum(1 .- field[16, 2:16]) +
            sum(1 .- field[2:16, 2]) + sum(1 .- field[2:16, 16])
        consumption = model.phi^2 * model.h^2 * sum(theta)
        @test edge_supply ≈ consumption atol = 1e-10

        @test_throws ArgumentError build_tissue_system(0, 1.0)
        @test_throws ArgumentError build_tissue_system(3, -1.0)
        @test_throws ArgumentError build_tissue_system(3, Inf)
        @test_throws ArgumentError build_tissue_system(3, 1.0; boundary = -1)
        @test_throws DimensionMismatch tissue_field(model, [1.0])
    end

    @testset "Second-order accuracy with an independent exact field" begin
        # θ = cosh(ξ) cosh(η) solves -∇²θ + 2θ = 0 exactly.
        # Supply its nonuniform boundary values directly; the lab uses constant boundaries.
        errors = Float64[]
        for n in (7, 15, 31)
            model = build_tissue_system(n, sqrt(2.0))
            rhs = zeros(n*n)
            exact = zeros(n*n)
            for j in 1:n, i in 1:n
                p = i + (j - 1)*n
                xi = -1 + i*model.h
                eta = -1 + j*model.h
                exact[p] = cosh(xi)*cosh(eta)
                i == 1 && (rhs[p] += cosh(-1)*cosh(eta))
                i == n && (rhs[p] += cosh(1)*cosh(eta))
                j == 1 && (rhs[p] += cosh(xi)*cosh(-1))
                j == n && (rhs[p] += cosh(xi)*cosh(1))
            end
            push!(errors, norm(model.A \ rhs - exact, Inf))
        end
        @test 3.8 < errors[1]/errors[2] < 4.2
        @test 3.8 < errors[2]/errors[3] < 4.2
        println("L6d manufactured-field errors: ", errors)
    end

    @testset "Course solvers, spectral radius, and reference source" begin
        model = build_tissue_system(15, 2.0)
        direct = model.A \ model.b
        initial = zeros(length(model.b))
        methods = (OxygenCourseSolvers.JacobiMethod(), OxygenCourseSolvers.GaussSeidelMethod(),
            OxygenCourseSolvers.SuccessiveOverRelaxationMethod())
        for algorithm in methods
            archive = OxygenCourseSolvers.solve(model.A, model.b, initial;
                algorithm = algorithm, ω = 1.5, ϵ = 1e-8, maxiterations = 2000)
            result = summarize_archive(model, archive; tolerance = 1e-8)
            @test result.converged
            @test norm(result.solution - direct, Inf) < 1e-6
            @test first(result.residuals) == norm(model.b)
            @test last(result.residuals) == norm(model.b - model.A*result.solution)
            @test result.residuals[end - 1] >= 1e-8
            @test initial == zeros(length(initial))
            if algorithm isa OxygenCourseSolvers.JacobiMethod
                my_residual = model.b - model.A*initial
                my_next = initial + my_residual ./ diag(model.A)
                @test my_next ≈ archive[1]
            end
        end
        @test !summarize_archive(model, Dict(0 => initial)).converged
        @test summarize_archive(model, Dict(0 => direct)).iterations == 0

        for phi in (0.0, 2.0)
            small = build_tissue_system(3, phi)
            G = Matrix{Float64}(I, 9, 9) - Diagonal(diag(small.A)) \ small.A
            expected = 4cos(pi/4)/(4 + (phi*small.h)^2)
            @test maximum(abs, eigvals(G)) ≈ expected
        end

        student = split(read(joinpath(WEEK_ROOT, "L6d", "src", "Compute.jl"), String), "module L6dOxygen"; limit = 2)[2]
        reference = split(read(joinpath(WEEK_ROOT, "L6d", "src", "Compute-solution.jl"), String), "module L6dOxygen"; limit = 2)[2]
        @test student == reference
        @test plot_tissue(model, direct) isa Plots.Plot
        @test plot_tissue(model, direct; theme = :dark) isa Plots.Plot
    end
end
