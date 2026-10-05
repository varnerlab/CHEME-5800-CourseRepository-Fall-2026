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
        x = collect(1.0:20.0)
        X = reshape(x, :, 1)
        y = 2.0 .+ 3.0 .* x
        fit = ols_fit(X, y)
        report = regression_report(y, fit.predictions)
        @test fit.coefficients ≈ [2.0, 3.0]
        @test report.rmse < 1e-12
        @test report.r2 ≈ 1.0
        @test norm(transpose(fit.design) * fit.residuals) < 1e-10
        @test_throws DimensionMismatch ols_fit(X, y[1:end-1])
        @test_throws DimensionMismatch regression_report(y, y[1:end-1])
    end
end
