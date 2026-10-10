using Test, LinearAlgebra, Random, Statistics
import JSON  # reads the lab notebook whose cells the suite runs
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells

@testset "L8d cross-validation for ridge regression" begin
    @testset "Ridge helpers" begin
        Random.seed!(8)
        X_train = randn(40, 3) .* [1.0 10.0 100.0] .+ [5.0 -2.0 0.5]
        X_other = randn(7, 3)
        Z_train, Z_other = L8dRidgeCV.scale_features(X_train, X_other)
        @test maximum(abs, mean(Z_train, dims = 1)) < 1e-12
        @test all(std(Z_train, dims = 1) .≈ 1)
        @test Z_other ≈ (X_other .- mean(X_train, dims = 1)) ./ std(X_train, dims = 1) # training statistics
        @test_throws DimensionMismatch L8dRidgeCV.scale_features(X_train, randn(7, 2))
        @test_throws ArgumentError L8dRidgeCV.scale_features(hcat(X_train, ones(40)), randn(7, 4))

        y = 3.0 .+ Z_train * [1.0, -2.0, 0.5] .+ 0.1 .* randn(40)
        X̂ = hcat(Z_train, ones(40))
        @test L8dRidgeCV.ridge_fit(Z_train, y, 0.0) ≈ X̂ \ y # δ = 0 is ordinary least squares, intercept last
        for δ ∈ (0.0, 1.0, 100.0, 1e6)
            # centered features: the unpenalized intercept is the average response for every δ -
            @test L8dRidgeCV.ridge_fit(Z_train, y, δ)[end] ≈ mean(y)
        end
        weights(δ) = norm(L8dRidgeCV.ridge_fit(Z_train, y, δ)[1:3])
        @test weights(0.0) > weights(10.0) > weights(1000.0)
        @test L8dRidgeCV.ridge_fit(Z_train, y, 2) ≈ L8dRidgeCV.ridge_fit(Z_train, y, 2.0) # an integer δ works
        @test L8dRidgeCV.ridge_predict(L8dRidgeCV.ridge_fit(Z_train, y, 0.0), Z_train) ≈ X̂ * (X̂ \ y)
        @test_throws DimensionMismatch L8dRidgeCV.ridge_fit(Z_train, y[1:end-1], 1.0)
        @test_throws ArgumentError L8dRidgeCV.ridge_fit(Z_train, y, -1.0)
        @test_throws ArgumentError L8dRidgeCV.ridge_fit(Z_train, y, Inf)
        @test_throws DimensionMismatch L8dRidgeCV.ridge_predict(ones(3), Z_train)
    end

    @testset "Reference cross-validation" begin
        Random.seed!(80)
        X = randn(53, 4)
        y = X * [1.0, 0.0, -1.0, 2.0] .+ 0.3 .* randn(53)
        δ_values = [0.0, 0.1, 10.0, 1000.0]
        result = L8dRidgeCV.my_cross_validation(X, y, δ_values; k = 5, seed = 11)
        @test sort(vcat(result.folds...)) == collect(1:53) # every row validated exactly once
        @test length.(result.folds) == [10, 10, 10, 10, 13] # the last fold takes the leftover rows
        @test result.δ_values == δ_values
        @test result == L8dRidgeCV.my_cross_validation(X, y, δ_values; k = 5, seed = 11)
        @test length.(L8dRidgeCV.my_cross_validation(X, y, δ_values; k = 10).folds) == [fill(5, 9); 8] # as the docstring says

        # an independent recomputation of CV_k(δ) and its spread for every δ -
        for (i, δ) ∈ enumerate(δ_values)
            errors = Float64[]
            for validation ∈ result.folds
                training = setdiff(1:53, validation)
                μ, s = mean(X[training, :], dims = 1), std(X[training, :], dims = 1)
                A = hcat((X[training, :] .- μ) ./ s, ones(length(training)))
                B = hcat((X[validation, :] .- μ) ./ s, ones(length(validation)))
                J = Diagonal([ones(4); 0.0])
                θ = (A'A + δ * J) \ (A'y[training])
                push!(errors, mean(abs2, y[validation] - B * θ))
            end
            @test result.mean_errors[i] ≈ mean(errors)
            @test result.std_errors[i] ≈ std(errors)
        end
        @test argmin(result.mean_errors) < length(δ_values) # the largest penalty underfits
        @test_throws ArgumentError L8dRidgeCV.my_cross_validation(X, y, δ_values; k = 1)
        @test_throws ArgumentError L8dRidgeCV.my_cross_validation(X, y, δ_values; k = 54)
        @test_throws ArgumentError L8dRidgeCV.my_cross_validation(X, y, [1.0, -1.0])
        @test_throws DimensionMismatch L8dRidgeCV.my_cross_validation(X, y[1:end-1], δ_values)
    end

    @testset "Student stub" begin
        # The student file is the reference apart from its header and the three TODO steps.
        student_text = read(joinpath(WEEK_ROOT, "L8d", "src", "Compute.jl"), String)
        reference_text = read(joinpath(WEEK_ROOT, "L8d", "src", "Compute-solution.jl"), String)
        @test all(occursin("# TODO $i:", student_text) for i in 1:3)
        body(text) = split(text, "module L8dRidgeCV"; limit = 2)[2]
        before(text) = split(body(text), "# TODO 1:"; limit = 2)[1]
        after(text) = split(body(text), "# Every entry should now hold a number"; limit = 2)[2]
        @test before(student_text) == before(reference_text)
        @test after(student_text) == after(reference_text)
        student_module = Module(:L8dStudent)
        Base.include(student_module, joinpath(WEEK_ROOT, "L8d", "src", "Compute.jl"))
        error = try
            student_module.L8dRidgeCV.my_cross_validation(randn(20, 2), randn(20), [1.0])
            nothing
        catch caught
            caught
        end
        @test error isa ErrorException && occursin("Oooops!", error.msg)
    end

    @testset "L8d lab notebook" begin
        # Run the actual notebook cells with the reference my_cross_validation(...) in place of the stub -
        path = joinpath(WEEK_ROOT, "L8d", "CHEME-5800-L8d-Lab-CrossValidationAndResidualModelChecking-Fall-2026.ipynb")
        notebook = JSON.parsefile(path)
        workspace = Module(:L8dNotebookValidation)
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
        @test occursin("Include.jl", sources[1])
        for (index, source) in enumerate(sources)
            Base.include_string(REPL.softscope, workspace, source, joinpath(dirname(path), "validation-cell-$(index).jl"))
            if index == 1 # the setup cell loaded the stub; replace it with the reference
                Base.include(workspace, joinpath(WEEK_ROOT, "L8d", "src", "Compute-solution.jl"))
            end
        end
        w = workspace
        rmse(a, b) = sqrt(mean(abs2, a - b))

        # data: 84 features, the L7d split -
        @test size(w.X84) == (545, 84) && length(w.names84) == 84
        @test w.X84[:, 1:12] == w.X
        @test count(name -> occursin("×", name), w.names84) == 72 # 78 products minus the six constant squares
        @test (size(w.X12_train, 1), size(w.X12_test, 1)) == (436, 109)
        Random.seed!(1234)
        @test w.y_train == w.y[randperm(545)[1:436]] # the same split as L7d

        # Task 1 table -
        table = w.errors_table
        @test table.training_rmse == [1.053, 0.871]
        @test table.testing_rmse == [1.092, 1.304]

        # Task 2: the cross-validation curve and the final model -
        cv = w.cv_results
        @test w.δ_optimal ≈ 100.0
        @test round(cv.mean_errors[1]; digits = 4) == 1.4315
        @test round(minimum(cv.mean_errors); digits = 4) == 1.1201
        @test round(cv.mean_errors[end]; digits = 2) == 2.12
        @test length.(cv.folds) == [fill(43, 9); 49]
        @test w.θ̂_optimal[end] ≈ mean(w.y_train) # unpenalized intercept on centered features
        ŷ_train = L8dRidgeCV.ridge_predict(w.θ̂_optimal, w.Z84_train)
        @test round(rmse(w.y_train, ŷ_train); digits = 3) == 0.964
        @test round(rmse(w.y_test, L8dRidgeCV.ridge_predict(w.θ̂_optimal, w.Z84_test)); digits = 3) == 1.062

        # residuals of the selected model: no clear trend, wider for the expensive houses -
        r = w.y_train - ŷ_train
        @test abs(cor(r, ŷ_train)) < 0.1
        ordered = r[sortperm(ŷ_train)]
        third = length(ordered) ÷ 3
        # the same thirds the notebook prints: the last third also takes the leftover house -
        @test round.([std(ordered[1:third]), std(ordered[(third + 1):(2third)]), std(ordered[(2third + 1):end])];
            digits = 2) == [0.63, 0.92, 1.25]

        # other random splits: the twelve-feature model wins on 3 of 10 -
        twelve_wins = 0
        for seed ∈ 1:10
            Random.seed!(seed)
            rows = randperm(545)
            train, test = rows[1:436], rows[437:end]
            A12, B12 = L8dRidgeCV.scale_features(w.X[train, :], w.X[test, :])
            A84, B84 = L8dRidgeCV.scale_features(w.X84[train, :], w.X84[test, :])
            split_cv = L8dRidgeCV.my_cross_validation(w.X84[train, :], w.y[train], w.δ_values; k = 10, seed = 5800)
            δ = w.δ_values[argmin(split_cv.mean_errors)]
            twelve = rmse(w.y[test], L8dRidgeCV.ridge_predict(L8dRidgeCV.ridge_fit(A12, w.y[train], 0.001), B12))
            larger = rmse(w.y[test], L8dRidgeCV.ridge_predict(L8dRidgeCV.ridge_fit(A84, w.y[train], δ), B84))
            twelve_wins += twelve < larger
        end
        @test twelve_wins == 3

        # Task 3: the twelve-feature curve is flat until δ = 100 -
        cv12 = w.cv12_results
        @test round(w.δ12_optimal; digits = 1) == 31.6
        flat = cv12.mean_errors[cv12.δ_values .<= 100]
        @test round(minimum(flat); digits = 2) == 1.18 && round(maximum(flat); digits = 2) == 1.19
        @test minimum(cv.mean_errors) < minimum(cv12.mean_errors)

        # Task 3: singular values and filter factors -
        σ12, σ84 = svdvals(w.Z12_train), svdvals(w.Z84_train)
        @test round(σ12[1] / σ12[end]; digits = 1) == 2.5
        @test round(σ84[1] / σ84[end]; digits = 0) == 63
        f12 = σ12 .^ 2 ./ (σ12 .^ 2 .+ w.δ12_optimal)
        f84 = σ84 .^ 2 ./ (σ84 .^ 2 .+ w.δ_optimal)
        @test minimum(f12) > 0.84
        @test count(f84 .> 0.9) == 11 && count(f84 .< 0.1) == 21
        area_squared = findfirst(==("area×area"), w.names84)
        @test round(cor(w.X84_train[:, 1], w.X84_train[:, area_squared]); digits = 2) == 0.97

        # Task 3 question: other fold seeds move δ* but barely change the testing error -
        for (seed, expected) ∈ ((1, 158.5), (2, 199.5))
            other = L8dRidgeCV.my_cross_validation(w.X84_train, w.y_train, w.δ_values; k = 10, seed = seed)
            δ = w.δ_values[argmin(other.mean_errors)]
            @test round(δ; digits = 1) == expected
            testing = rmse(w.y_test, L8dRidgeCV.ridge_predict(L8dRidgeCV.ridge_fit(w.Z84_train, w.y_train, δ), w.Z84_test))
            @test 1.06 < testing < 1.07
        end
    end
end
