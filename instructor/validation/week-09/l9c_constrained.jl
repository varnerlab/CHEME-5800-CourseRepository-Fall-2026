# A scalar execution of the advanced notebook's nested algorithm. The tests use
# independent closed-form solutions and KKT residuals as their reference.
module L9cConstrainedValidation

function solve(f, df, x0; inequalities = (), equalities = (),
    μ = big"4.0", ρ = big"1.0", τ = big"0.1", ε = big"0.001",
    ε_inner = big"1e-8", α0 = big"1.0", a = big"0.0001",
    K = 10_000, S = 20, B = 60)

    x = x0
    trace = NamedTuple[]
    for outer ∈ 1:S
        # Hold the weights fixed throughout this inner minimization -
        P(z) = f(z) - μ*sum((log(-g(z)) for (g, dg) ∈ inequalities); init = zero(z)) +
            sum((h(z)^2 for (h, dh) ∈ equalities); init = zero(z))/(2ρ)
        gradient(z) = df(z) +
            μ*sum((dg(z)/(-g(z)) for (g, dg) ∈ inequalities); init = zero(z)) +
            sum((h(z)*dh(z) for (h, dh) ∈ equalities); init = zero(z))/ρ
        steps, backtracks = 0, 0

        for k ∈ 0:K
            q = gradient(x)
            abs(q) ≤ ε_inner && break # a stationary start needs no line search
            k == K && return (x = x, status = :inner_limit, trace = trace)
            α = α0 # reset the trial step for each new direction
            accepted = false
            for b ∈ 0:B
                candidate = x - α*q
                candidate == x && return (x = x, status = :line_search_failed, trace = trace)
                # Check the domain before evaluating any logarithm -
                if all(g(candidate) < 0 for (g, dg) ∈ inequalities) &&
                    P(candidate) ≤ P(x) - a*α*q^2
                    x = candidate
                    accepted = true
                    break
                end
                backtracks += 1
                b < B && (α /= 2)
            end
            accepted || return (x = x, status = :line_search_failed, trace = trace)
            steps += 1
        end

        # Multipliers and residuals belong to these same, still-fixed weights -
        λ = [μ/(-g(x)) for (g, dg) ∈ inequalities]
        ν = [h(x)/ρ for (h, dh) ∈ equalities]
        stationarity = abs(df(x) +
            sum((λ[i]*dg(x) for (i, (g, dg)) ∈ enumerate(inequalities)); init = zero(x)) +
            sum((ν[j]*dh(x) for (j, (h, dh)) ∈ enumerate(equalities)); init = zero(x)))
        equality = maximum((abs(h(x)) for (h, dh) ∈ equalities); init = zero(x))
        complementarity = maximum((abs(λ[i]*g(x)) for (i, (g, dg)) ∈ enumerate(inequalities)); init = zero(x))
        push!(trace, (; x, μ, ρ, λ, ν, stationarity, equality, complementarity, steps, backtracks))
        if max(stationarity, equality, complementarity) ≤ ε
            return (x = x, status = :converged, trace = trace)
        end
        outer == S && return (x = x, status = :outer_limit, trace = trace)
        isempty(inequalities) || (μ *= τ)
        isempty(equalities) || (ρ *= τ)
    end
end

end # module L9cConstrainedValidation

@testset "L9c constrained optimization" begin
    setprecision(BigFloat, 256) do
        f(x) = (x - 2)^2
        df(x) = 2*(x - 2)
        notebook = JSON.parsefile(joinpath(WEEK_ROOT, "L9c", "CHEME-5800-L9c-Advanced-NonlinearOptimization-Fall-2026.ipynb"))
        prose = join(join(cell["source"]) for cell ∈ notebook["cells"])

        @testset "Active and inactive inequalities" begin
            for c ∈ (big"1.0", big"3.0")
                inequalities = ((x -> x - c, x -> one(x)),)
                result = L9cConstrainedValidation.solve(f, df, big"0.0"; inequalities)
                @test result.status == :converged
                @test length(result.trace) == 5
                @test abs(result.x - min(c, big"2.0")) < big"0.001"
                @test all(row.backtracks ≤ 61*row.steps for row ∈ result.trace)
                for row ∈ result.trace
                    # Solve the quadratic stationarity equation independently -
                    exact = (c + 2 - sqrt((c - 2)^2 + 2row.μ))/2
                    @test abs(row.x - exact) ≤ big"5e-9"
                    @test row.x < c && row.λ[1] > 0
                    @test row.stationarity ≤ big"1e-8"
                    @test row.complementarity ≈ row.μ
                    @test abs(2*(row.x - 2) + row.λ[1]) ≤ big"1e-8"
                    # Every number displayed in the notebook agrees after rounding -
                    values = (row.μ, row.x, c - row.x, row.λ[1])
                    displayed = "| " * join((string(round(Float64(v); digits = 6)) for v ∈ values), " | ") * " |"
                    @test occursin(displayed, prose)
                end
                if c == 1
                    @test result.trace[1].x == 0 && result.trace[1].steps == 0
                    @test result.trace[1].backtracks == 0
                    @test result.trace[1].complementarity == 4 # continue the outer loop
                    @test abs(result.trace[end].λ[1] - 2) < big"0.001"
                else
                    @test result.trace[end].λ[1] < big"0.001"
                end
            end
        end

        @testset "Equality penalty and bounded termination" begin
            equalities = ((x -> x - 1, x -> one(x)),)
            result = L9cConstrainedValidation.solve(f, df, big"0.0"; equalities)
            @test result.status == :converged
            @test abs(result.x - 1) ≤ big"0.001"
            @test abs(result.trace[end].ν[1] - 2) < big"0.002"
            for row ∈ result.trace
                exact = (4row.ρ + 1)/(2row.ρ + 1)
                @test abs(row.x - exact) ≤ big"5e-9"
                @test row.stationarity ≤ big"1e-8"
            end
            # The first trial crosses x = 1; reject it before taking its logarithm -
            inequalities = ((x -> x - 1, x -> one(x)),)
            blocked = L9cConstrainedValidation.solve(f, df, big"-1.0"; inequalities, B = 0)
            @test blocked.status == :line_search_failed && blocked.x == -1
            @test L9cConstrainedValidation.solve(f, df, big"-1.0"; inequalities, K = 1).status == :inner_limit
            stationary = L9cConstrainedValidation.solve(f, df, big"0.0"; inequalities, S = 1)
            @test stationary.status == :outer_limit && stationary.trace[1].steps == 0
            rounded = L9cConstrainedValidation.solve(x -> x^2, x -> 2x, 1.0;
                α0 = 1e-300, ε_inner = 1e-12)
            @test rounded.status == :line_search_failed && rounded.x == 1.0
        end
    end
end
