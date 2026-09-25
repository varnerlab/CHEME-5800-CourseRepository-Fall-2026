const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-06"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
released("L6a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-06", "L6a", "Include.jl"))
released("L6b") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-06", "L6b", "Include.jl"))
released("L6c") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-06", "L6c", "Include.jl"))
released("L6d") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-06", "L6d", "Include.jl"))

# L6b's reference implementation; the notebook setup loads the student file.
released("L6b") && include(joinpath(WEEK_ROOT, "L6b", "src", "Compute-solution.jl"))

@meeting "L6a" begin
    include(joinpath(@__DIR__, "l6a_stoichiometry.jl"))
    @testset "L6a urea-cycle flux balance (5430 code in L6a/src)" begin
        # The pipeline of the urea-cycle example, using the code in L6a/src.
        listofreactions = read_reaction_file(joinpath(WEEK_ROOT, "L6a", "data", "Network.net"))
        S, species, reactions, rd = build_stoichiometric_matrix(listofreactions)
        @test size(S) == (18, 19)
        model = build(MyPrimalFluxBalanceAnalysisCalculationModel, (
            S = S, fluxbounds = build_default_bounds_array(listofreactions), species = species,
            reactions = reactions, objective = zeros(length(reactions))))
        # Use the same parameter records and mmol/gDW/h basis as the reviewed notebook.
        thermo = CSV.read(joinpath(WEEK_ROOT, "L6a", "data", "urea_thermodynamics.csv"), DataFrame)
        turnover = CSV.read(joinpath(WEEK_ROOT, "L6a", "data", "urea_turnover_numbers.csv"), DataFrame)
        reversibility = Dict(row.reaction => Int(row.dg_prime_standard_kj_per_mol > -10.0)
            for row in eachrow(thermo))
        for row in eachrow(turnover)
            j = findfirst(==(row.reaction), model.reactions)
            vmax = row[Symbol("model_kcat_s-1")] * 0.01 * 3600.0
            model.fluxbounds[j, 1] = -reversibility[row.reaction] * vmax
            model.fluxbounds[j, 2] = vmax
        end
        model.objective[findfirst(==("b4"), model.reactions)] = -1
        solution = solve(model)
        flux = solution["argmax"]
        @test -flux[findfirst(==("b4"), model.reactions)] ≈ 118.08 atol = 1e-8 # urea export, mmol/gDW/h
        @test maximum(abs, S * flux) < 1e-8 # every species balances
        @test flux[findfirst(==("v5"), model.reactions)] ≈ 0.0 atol = 1e-10


    end

    @testset "Course-package flux balance solver (used by L6b)" begin
        S = [1.0 -1.0 0.0; 0.0 1.0 -1.0] # A -> B -> out, with uptake of A
        solution = solve_flux_balance(S, [0.0, 0.0, 0.0], [5.0, 3.0, 10.0], [0.0, 0.0, 1.0])
        @test solution.optimal && solution.objective ≈ 3.0
        @test check_flux_balance(S, solution.flux, [0.0, 0.0, 0.0], [5.0, 3.0, 10.0]).valid
        @test !solve_flux_balance(S, [4.0, 0.0, 0.0], [5.0, 3.0, 10.0], [0.0, 0.0, 1.0]).optimal
        @test_throws DimensionMismatch solve_flux_balance(S, [0.0], [1.0], [0.0])
        @test_throws ArgumentError solve_flux_balance(ones(1, 1), [Inf], [Inf], [1.0])
        @test_throws ArgumentError solve_flux_balance(ones(1, 1), [-Inf], [-Inf], [1.0])
        @test solve_flux_balance(ones(1, 1), [-Inf], [Inf], [0.0]).optimal # open bounds still work
    end
end

@meeting "L6b" begin
    @testset "L6b overflow metabolism" begin
        model = L6bOverflow.load_core_model(joinpath(WEEK_ROOT, "L6b", "data", "e_coli_core.json"))
        @test size(model.S) == (72, 95)
        @test length(model.exchanges) == 20
        @test model.biomass == "BIOMASS_Ecoli_core_w_GAM"
        flux_of(m, r, id) = r.flux[findfirst(==(id), m.reactions)]
        growth(m) = L6bOverflow.solve_growth(m)

        aerobic = growth(model)
        @test aerobic.optimal && isapprox(aerobic.growth, 0.8739; atol = 1e-3)
        @test L6bOverflow.flux_checks(model, aerobic).valid
        @test abs(flux_of(model, aerobic, "EX_ac_e")) < 1e-6 # no overflow with oxygen to spare
        @test isapprox(flux_of(model, aerobic, "EX_o2_e"), -21.80; atol = 0.01)

        capped = L6bOverflow.with_uptake_limit(model, "EX_o2_e", 15.0)
        r15 = growth(capped)
        @test isapprox(r15.growth, 0.7178; atol = 1e-3)
        @test isapprox(flux_of(capped, r15, "EX_ac_e"), 6.81; atol = 0.01) # acetate overflow
        @test model.lower[findfirst(==("EX_o2_e"), model.reactions)] == -1000.0 # input unchanged

        anaerobic = L6bOverflow.with_uptake_limit(model, "EX_o2_e", 0.0)
        r0 = growth(anaerobic)
        @test isapprox(r0.growth, 0.2117; atol = 1e-3)
        @test flux_of(anaerobic, r0, "EX_etoh_e") > 1.0 && flux_of(anaerobic, r0, "EX_for_e") > 1.0

        # Question answers recorded in the instructor notes.
        more_glucose = L6bOverflow.with_uptake_limit(capped, "EX_glc__D_e", 20.0)
        @test isapprox(growth(more_glucose).growth, 1.047; atol = 1e-3)
        low_glucose = L6bOverflow.with_uptake_limit(capped, "EX_glc__D_e", 6.5)
        @test abs(flux_of(low_glucose, growth(low_glucose), "EX_ac_e")) < 1e-6
        blocked = L6bOverflow.with_bounds(capped, "EX_ac_e", 0.0, 0.0)
        rb = growth(blocked)
        @test isapprox(rb.growth, 0.663; atol = 1e-3) && flux_of(blocked, rb, "EX_etoh_e") > 1.0
        @test isapprox(growth(L6bOverflow.with_bounds(model, "ATPM", 20.0, 20.0)).growth, 0.815; atol = 1e-3)

        @test_throws ArgumentError L6bOverflow.with_uptake_limit(model, "EX_o2_e", -1.0)
        @test_throws ArgumentError L6bOverflow.with_bounds(model, "not_a_reaction", 0.0, 1.0)
        @test_throws ArgumentError L6bOverflow.load_core_model(joinpath(WEEK_ROOT, "missing.json"))

        # The student file is the reference apart from its header, and the figure draws.
        student = split(read(joinpath(WEEK_ROOT, "L6b", "src", "Compute.jl"), String), "module L6bOverflow"; limit = 2)[2]
        reference = split(read(joinpath(WEEK_ROOT, "L6b", "src", "Compute-solution.jl"), String), "module L6bOverflow"; limit = 2)[2]
        @test student == reference
        @test L6bBoundaryPlots.plot_exchange_flows(model, aerobic) isa Plots.Plot
        @test L6bBoundaryPlots.plot_exchange_flows(anaerobic, r0; theme = :dark) isa Plots.Plot
    end
end

@meeting "L6c" "L6d" begin
    @testset "L6c/L6d stationary iterations" begin
        A = [4.0 -1.0 0.0; -1.0 4.0 -1.0; 0.0 -1.0 3.0]
        b = [15.0, 10.0, 10.0]
        direct = A \ b
        results = (
            stationary_solve(A, b; method = :jacobi),
            stationary_solve(A, b; method = :gauss_seidel),
            stationary_solve(A, b; method = :sor, omega = 1.1),
        )
        @test all(result.converged for result in results)
        @test all(result.solution ≈ direct for result in results)
        @test all(last(result.residuals) <= 1e-10 for result in results)
        @test results[3].iterations < results[1].iterations
        D = Diagonal(diag(A))
        @test spectral_radius(Matrix(I, 3, 3) - D \ A) < 1
        @test_throws ArgumentError stationary_solve(A, b; method = :unknown)
        @test_throws ArgumentError stationary_solve(A, b; method = :sor, omega = 2.0)
    end
end

@meeting "L6c" begin
    include(joinpath(@__DIR__, "course_solver_stopping.jl"))
end
