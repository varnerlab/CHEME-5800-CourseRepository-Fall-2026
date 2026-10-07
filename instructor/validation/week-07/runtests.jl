const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the example notebooks whose cells the suite runs
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells
released("L7a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7a", "Include.jl"))
released("L7b") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7b", "Include.jl"))
released("L7c") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7c", "Include.jl"))
released("L7d") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7d", "Include.jl"))

@meeting "L7a" begin
    @testset "L7a Fun with SVD example" begin
        # Run the actual notebook cells so setup and the data path are tested too -
        path = joinpath(WEEK_ROOT, "L7a", "CHEME-5800-L7a-Example-FunWithSVD-Fall-2026.ipynb")
        notebook = JSON.parsefile(path)
        workspace = Module(:L7aNotebookValidation)
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        for (index, cell) in enumerate(notebook["cells"])
            cell["cell_type"] == "code" || continue
            source = join(cell["source"])
            # Jupyter's soft scope lets the reconstruction loop update the global `M` -
            Base.include_string(REPL.softscope, workspace, source,
                joinpath(dirname(path), "validation-cell-$(index).jl"))
        end
        @test size(workspace.image_array) == (512, 512)
        @test issorted(workspace.Σ; rev = true)
        @test workspace.R == length(workspace.image_frames_dictionary)
        # Adding every frame must give back the image; this catches a swapped U and V -
        frames = workspace.image_frames_dictionary
        @test sum(Float64.(frames[i]) for i ∈ 1:workspace.R) ≈ workspace.image_array
        @test rank(workspace.M) == workspace.number_of_frames
    end
end

@meeting "L7b" begin
    @testset "L7b platelet stoichiometric-matrix SVD" begin
        # Run the actual notebook cells so setup and cache paths are tested too -
        path = joinpath(WEEK_ROOT, "L7b", "CHEME-5800-L7b-Lab-SVD-StoichiometricMatrix-Fall-2026.ipynb")
        notebook = L7bBiGG.JSON.parsefile(path)
        workspace = Module(:L7bNotebookValidation)
        # A plain module needs an include method for the notebook setup cell.
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        # The distributed lab leaves TODO 1 unanswered; fill only this in-memory copy -
        placeholder = "S_k = nothing;"
        answer = "S_k = U[:, 1:k] * Diagonal(Σ[1:k]) * transpose(V[:, 1:k]);"
        sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
        @test count(source -> occursin(placeholder, source), sources) == 1
        @test any(source -> occursin("# TODO 1:", source), sources)
        for (index, source) in enumerate(sources)
            Base.include_string(workspace, replace(source, placeholder => answer),
                joinpath(dirname(path), "validation-cell-$(index).jl"))
        end
        @test size(workspace.S) == (738, 1008)
        @test count(!iszero, workspace.S) == 4006
        @test workspace.r == 719
        @test size(workspace.U0) == (738, 19)
        @test size(workspace.V0) == (1008, 289)
        @test workspace.left_residual < workspace.τ
        @test workspace.right_residual < workspace.τ
        @test workspace.relative_error ≈ sqrt(1 - workspace.retained_fraction[workspace.k])
        @test workspace.relative_error ≈ 0.1879 atol = 1e-4
        @test size(workspace.approximation_image) == size(workspace.original_image) == size(workspace.S)

        # Values the prose quotes: modes needed for 50, 90, and 99 percent -
        F = workspace.retained_fraction
        @test [findfirst(>=(p), F) for p ∈ (0.5, 0.9, 0.99)] == [4, 223, 534]
        # Roundoff-level values differ between machines, so pin only the gap the prose quotes -
        @test workspace.σ_next < workspace.τ < workspace.Σ[workspace.r]
        @test isapprox(workspace.τ, 9.45e-12; rtol = 0.01) && isapprox(workspace.Σ[workspace.r], 0.0323; rtol = 0.01)
        @test workspace.Σ[workspace.r] / workspace.σ_next > 1e10

        # Nullspace basis columns change with BLAS rounding; Task 3 uses projections, which do not -
        # The trial flux (HEX1 projected onto the right nullspace): 416 irreversible reactions run backward -
        @test length(workspace.below_lower) == 416 && isempty(workspace.above_upper)
        @test length(workspace.violations) == 416
        @test all(workspace.lower_bounds[workspace.below_lower] .== 0.0)
        @test count(==(0.0), workspace.lower_bounds) == 559
        @test workspace.v_trial[workspace.hexokinase_index] ≈ 0.4964 atol = 1e-4
        # The nine-row flux table must not end inside a tie, or its last row varies by machine -
        flux_order = sortperm(abs.(workspace.v_trial); rev = true)
        @test abs(workspace.v_trial[flux_order[9]]) - abs(workspace.v_trial[flux_order[10]]) > 1e-6

        # The NAD+ relation (e_nad_c projected onto the left nullspace) is exactly one conserved pool -
        ids = [metabolite["id"] for metabolite in workspace.model["metabolites"]]
        nad_pool = ["nad_c", "nadh_c", "nmn_c", "rnam_c", "ncam_c"]
        w = workspace.U0 * workspace.U0[findfirst(==("nad_c"), ids), :]
        nonzero = findall(x -> abs(x) > 1e-10, w)
        @test Set(ids[nonzero]) == Set(nad_pool)
        @test all(x -> isapprox(x, 0.2; atol = 1e-10), w[nonzero])
        @test maximum(abs, transpose(workspace.S) * [id ∈ nad_pool ? 1.0 : 0.0 for id ∈ ids]) == 0.0

        # Single-entry columns are the exchange, sink, and demand reactions in Task 1's question -
        single = [j for j ∈ axes(workspace.S, 2) if count(!iszero, workspace.S[:, j]) == 1]
        @test all(j -> split(workspace.model["reactions"][j]["id"], "_")[1] ∈ ("EX", "SK", "DM"), single)

        # Check the uncached branch's URL and parser without a live download -
        endpoint = MyBiggModelsDownloadModelEndpointModel()
        endpoint.bigg_id = "iAT_PLT_636"
        @test build("https://bigg.ucsd.edu", endpoint) == "https://bigg.ucsd.edu/api/v2/models/iAT_PLT_636/download"
        @test L7bBiGG._default_handler_process_bigg_response(typeof(endpoint), "{\"id\":\"iAT_PLT_636\"}")["id"] == "iAT_PLT_636"
    end
end

@meeting "L7d" begin
    @testset "L7d OLS contracts" begin
        # exact line: the L7c augmented matrix puts the ones column last -
        x = collect(1.0:20.0)
        X̂ = hcat(x, ones(20))
        y = 3.0 .* x .+ 2.0
        model = ols_fit(X̂, y)
        report = regression_report(y, X̂ * model.θ̂)
        @test model.θ̂ ≈ [3.0, 2.0]
        @test report.rmse < 1e-12
        @test report.r2 ≈ 1.0
        @test norm(transpose(X̂) * model.residuals) < 1e-10

        # noisy line: θ̂ matches a QR solve, and σ̂² and SE follow the L7c formulas -
        noisy = y .+ [isodd(i) ? 0.5 : -0.5 for i ∈ 1:20]
        noisy_model = ols_fit(X̂, noisy)
        @test noisy_model.θ̂ ≈ X̂ \ noisy
        @test noisy_model.σ̂² ≈ sum(abs2, noisy - X̂ * noisy_model.θ̂) / (20 - 2)
        @test noisy_model.SE ≈ sqrt.(noisy_model.σ̂² .* diag(inv(transpose(X̂) * X̂)))

        @test_throws DimensionMismatch ols_fit(X̂, y[1:end-1])
        @test_throws ArgumentError ols_fit(ones(2, 2), ones(2))
        @test_throws DimensionMismatch regression_report(y, y[1:end-1])
    end

    @testset "L7d housing-price notebook" begin
        # Run the actual notebook cells so the data path, the check, and the what-if are tested too -
        path = joinpath(WEEK_ROOT, "L7d", "CHEME-5800-L7d-Lab-HousingPriceOLS-Fall-2026.ipynb")
        notebook = JSON.parsefile(path)
        workspace = Module(:L7dNotebookValidation)
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        for (index, cell) in enumerate(notebook["cells"])
            cell["cell_type"] == "code" || continue
            Base.include_string(REPL.softscope, workspace, join(cell["source"]),
                joinpath(dirname(path), "validation-cell-$(index).jl"))
        end

        # facts the prose relies on: sizes, fit, and conditioning -
        @test size(workspace.X) == (545, 12)
        @test size(workspace.X̂_train) == (436, 13)
        @test round(workspace.training_report.r2; digits = 3) == 0.678
        @test round(workspace.testing_report.r2; digits = 3) == 0.677
        @test round(cond(workspace.X̂_train)) == 44
        @test norm(workspace.θ̂ - workspace.θ̂_svd) < 1e-12

        # Task 3: only the bedrooms and guestroom intervals contain zero (seed 1234) -
        model = workspace.model
        contains_zero = (model.θ̂ .- 1.96 .* model.SE .≤ 0) .& (model.θ̂ .+ 1.96 .* model.SE .≥ 0)
        @test workspace.feature_names[findall(contains_zero)] == ["bedrooms", "guestroom"]
        hot_water = findfirst(==("hotwaterheating"), workspace.feature_names)
        @test count(workspace.X̂_train[:, hot_water] .== 1) == 24

        # residual plot: the spread grows with the predicted price, and the large residuals are positive -
        ŷ = workspace.X̂_train * workspace.θ̂
        r = model.residuals[sortperm(ŷ)] # residuals ordered by predicted price
        third = length(r) ÷ 3
        @test std(r[(2 * third + 1):end]) > 1.5 * std(r[1:third])
        @test 4.5 < maximum(r) < 5.5
        @test -3.0 < minimum(r) < -2.5

        # feature selection: testing rmse for the cell's three choices of `dropped` -
        function testing_rmse(dropped)
            keep = [findall(name -> name ∉ dropped, workspace.feature_names); size(workspace.X̂_train, 2)]
            smaller = ols_fit(workspace.X̂_train[:, keep], workspace.y_train)
            return regression_report(workspace.y_test, workspace.X̂_test[:, keep] * smaller.θ̂).rmse
        end
        @test round(workspace.testing_report.rmse; digits = 3) == 1.092
        @test round(testing_rmse(["bedrooms", "guestroom"]); digits = 3) == 1.101
        @test round(testing_rmse(["bedrooms"]); digits = 3) == 1.088
        @test round(testing_rmse(["airconditioning"]); digits = 3) == 1.207

        # across ten splits, removing bedrooms and guestroom changes testing rmse by -0.03 to +0.02, both signs -
        changes = Float64[]
        for seed ∈ [1234, 1, 2, 3, 7, 11, 42, 99, 2024, 31415]
            Random.seed!(seed)
            rows = randperm(545)
            train, test = rows[1:436], rows[437:end]
            A, B = hcat(workspace.X[train, :], ones(436)), hcat(workspace.X[test, :], ones(109))
            keep = [findall(name -> name ∉ ["bedrooms", "guestroom"], workspace.feature_names); 13]
            full = regression_report(workspace.y[test], B * ols_fit(A, workspace.y[train]).θ̂).rmse
            smaller = regression_report(workspace.y[test], B[:, keep] * ols_fit(A[:, keep], workspace.y[train]).θ̂).rmse
            push!(changes, smaller - full)
        end
        @test -0.035 < minimum(changes) < -0.025
        @test 0.015 < maximum(changes) < 0.025

        # what-if: the duplicated area column leaves rank 13 and the predictions unchanged -
        X̂_train = workspace.X̂_train
        X̂_what_if = hcat(X̂_train, 92.90304 * X̂_train[:, 1])
        S = svdvals(X̂_what_if)
        @test S[end] / S[1] < 1e-14
        @test S[end-1] / S[1] > 1e-6
        @test rank(transpose(X̂_what_if) * X̂_what_if) == 13
        @test maximum(abs.(X̂_what_if * workspace.θ̂_what_if - X̂_train * workspace.θ̂)) < 1e-10
    end
end
