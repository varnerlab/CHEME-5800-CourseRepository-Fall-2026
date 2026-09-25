const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
released("L7a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7a", "Include.jl"))
released("L7b") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7b", "Include.jl"))
released("L7c") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7c", "Include.jl"))
released("L7d") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-07", "L7d", "Include.jl"))

@meeting "L7a" begin
    @testset "L7a SVD contracts" begin
        A = [3.0 2.0 2.0; 2.0 3.0 -2.0]
        rank_one = truncated_svd(A, 1)
        rank_two = truncated_svd(A, 2)
        @test rank_two.approximation ≈ A
        @test rank_two.relative_error < 1e-12
        @test rank_one.relative_error > rank_two.relative_error
        @test issorted(rank_two.explained)
        @test rank_two.explained[end] ≈ 1.0
        @test_throws ArgumentError truncated_svd(A, 0)
    end
end

@meeting "L7b" begin
    @testset "L7b platelet stoichiometric-matrix SVD" begin
        # Run the actual notebook cells so setup and cache paths are tested too -
        path = joinpath(WEEK_ROOT, "L7b", "CHEME-5800-L7b-Example-SVD-StoichiometricMatrix-Fall-2026.ipynb")
        notebook = L7bBiGG.JSON.parsefile(path)
        workspace = Module(:L7bNotebookValidation)
        # A plain module needs an include method for the notebook setup cell.
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        for (index, cell) in enumerate(notebook["cells"])
            cell["cell_type"] == "code" || continue
            source = join(cell["source"])
            Base.include_string(workspace, source, joinpath(dirname(path), "validation-cell-$(index).jl"))
        end
        @test size(workspace.S) == (738, 1008)
        @test workspace.r == 719
        @test size(workspace.U0) == (738, 19)
        @test size(workspace.V0) == (1008, 289)
        @test workspace.left_residual < workspace.τ
        @test workspace.right_residual < workspace.τ
        @test workspace.relative_error ≈ sqrt(1 - workspace.retained_fraction[workspace.k])
        @test workspace.relative_error ≈ 0.1879 atol = 1e-4
        @test !isempty(workspace.violations)
        @test size(workspace.cumulative_image) == size(workspace.original_image) == size(workspace.S)

        # Check the uncached branch's URL and parser without a live download -
        endpoint = MyBiggModelsDownloadModelEndpointModel()
        endpoint.bigg_id = "iAT_PLT_636"
        @test build("https://bigg.ucsd.edu", endpoint) == "https://bigg.ucsd.edu/api/v2/models/iAT_PLT_636/download"
        @test L7bBiGG._default_handler_process_bigg_response(typeof(endpoint), "{\"id\":\"iAT_PLT_636\"}")["id"] == "iAT_PLT_636"
    end
end

@meeting "L7c" "L7d" begin
    @testset "L7c/L7d OLS contracts" begin
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
