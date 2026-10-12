using Test, LinearAlgebra, Random, Statistics
import JSON  # reads the example notebook whose cells the suite runs
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells

@testset "L8c housing ridge example and condition-number companion" begin
    # Run the example's code cells; its own "Ridge regression estimate checks" testset records here -
    path = joinpath(WEEK_ROOT, "L8c", "CHEME-5800-L8c-Example-RLS-SVD-HousingPriceModel-Fall-2026.ipynb")
    notebook = JSON.parsefile(path)
    workspace = Module(:L8cExampleValidation)
    Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
    sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
    @test occursin("Include.jl", sources[1])
    for (index, source) in enumerate(sources)
        Base.include_string(REPL.softscope, workspace, source, joinpath(dirname(path), "validation-cell-$(index).jl"))
    end
    w = workspace
    column(name) = findfirst(==(name), w.feature_labels)

    @testset "Example: data and split" begin
        # the L7d recoding and feature order, prices in millions -
        @test w.feature_labels == ["area", "bedrooms", "bathrooms", "stories", "mainroad", "guestroom", "basement",
            "hotwaterheating", "airconditioning", "parking", "prefarea", "furnishingstatus", "intercept"]
        @test size(w.X) == (545, 12) && extrema(w.y) == (1.75, 13.3) # "between 1.75 and 13.3 million USD"
        @test sort(unique(w.X[:, column("mainroad")])) == [-1.0, 1.0]
        @test sort(unique(w.X[:, column("furnishingstatus")])) == [-1.0, 0.0, 1.0]
        @test (size(w.training.X), size(w.testing.X)) == ((436, 13), (109, 13))
        @test all(w.training.X[:, end] .== 1) # the intercept column is last
    end

    @testset "Example: quoted results" begin
        # Task 1: both errors close to one million -
        @test round(w.ϵ_train; digits = 3) == 1.082 && round(w.ϵ_test; digits = 3) == 0.963

        # Task 2, δ = 1: bedrooms up about 20%, intercept down about 7.5%, the two largest changes -
        @test w.δ == 1.0
        Δ = (w.θ̂₂ .- w.θ̂₁) ./ abs.(w.θ̂₁)
        @test round(Δ[column("bedrooms")]; digits = 2) == 0.20
        @test round(Δ[column("intercept")]; digits = 3) == -0.075
        @test Set(partialsortperm(abs.(Δ), 1:2; rev = true)) == Set([column("bedrooms"), column("intercept")])
        @test 0.04 < 1 - norm(w.θ̂₂) / norm(w.θ̂₁) < 0.05 # "about 4% shorter"
        @test abs(w.ϵ_test_regularization - w.ϵ_test) / w.ϵ_test < 0.001 # "less than 0.1%"

        # the suggested penalties δ = 10 and 100 make the training error grow -
        X̂, y = w.training.X, w.training.y
        training_rmse(δ) = norm(y - X̂ * (inv(X̂' * X̂ + δ * I) * X̂' * y)) / sqrt(length(y))
        @test training_rmse(1.0) ≈ w.ϵ_training_regularization
        @test training_rmse(1.0) < training_rmse(10.0) < training_rmse(100.0)

        # Task 3: filter factors, condition number, and the direction of the change -
        f = w.S .^ 2 ./ (w.S .^ 2 .+ w.δ)
        @test all(f[1:12] .> 0.98) && round(1 - f[13]; digits = 2) == 0.08 # "shrinks it by about 8%"
        @test round(w.S[1] / w.S[end]; digits = 2) == 42.16
        c = w.V' * (w.θ̂₂ - w.θ̂₁) # the change in the right singular vector basis; sign-free tests only
        @test c[end]^2 / sum(abs2, c) > 0.98 # almost all of it along v₁₃
        @test w.V[column("intercept"), end]^2 > 0.9 # v₁₃ points mostly along the intercept
        features = X̂[:, 1:12]
        ones_column = X̂[:, end]
        @test norm(ones_column - features * (features \ ones_column)) < 0.2 * norm(ones_column) # near dependence
        @test w.θ̂₃ ≈ w.θ̂₂
    end

    @testset "Condition-number companion: quoted numbers" begin
        # the housing values come from the example's training split -
        X̂ = w.training.X
        @test round(cond(X̂); digits = 2) == 42.16
        @test round(cond(X̂' * X̂)) == 1777 # "about 1800"
        σ = svdvals(X̂)
        @test round(σ[end]^2; digits = 1) == 11.5
        @test round((σ[1]^2 + 1) / (σ[end]^2 + 1)) == 1635 # δ = 1: "about 1600"
        X̂_square_feet = copy(X̂)
        X̂_square_feet[:, column("area")] .*= 1000
        @test 33_500 < cond(X̂_square_feet) < 34_500 # "about 34,000"

        # the two-by-two example -
        A = [1 1; 1 1.0001]
        b = [2, 2.0001]
        @test isapprox(A \ [2, 2.0002], [0, 2]; atol = 1e-8)
        @test round(cond(A); sigdigits = 2) == 4.0e4
        relative_data = 1e-4 / norm(b)
        @test round(relative_data; sigdigits = 2) == 3.5e-5
        @test round((1 / relative_data) / cond(A); digits = 1) == 0.7 # "about 70 percent of the bound"
        x = A \ b
        @test 11 < -log10(abs(x[1] - 1)) < 12 # "between 11 and 12" correct digits
    end
end
