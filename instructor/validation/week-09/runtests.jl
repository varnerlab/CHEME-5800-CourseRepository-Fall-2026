const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-09"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the lab notebook whose cells the suite runs
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells
import JuMP, GLPK  # the L9a separability check solves a small linear program
released("L9a") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-09", "L9a", "Include.jl"))
released("L9b") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-09", "L9b", "Include.jl"))
# L9b's reference implementation; the notebook setup loads the student file.
released("L9b") && include(joinpath(WEEK_ROOT, "L9b", "src", "Compute-solution.jl"))
released("L9c") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-09", "L9c", "Include.jl"))
released("L9d") && include(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-09", "L9d", "Include.jl"))
# L9d's reference implementation; the notebook setup loads the student file.
released("L9d") && include(joinpath(WEEK_ROOT, "L9d", "src", "Compute-solution.jl"))

@meeting "L9a" begin
    @testset "L9a banknote Perceptron example" begin
        # Run the example notebook's code cells in a fresh module -
        path = joinpath(WEEK_ROOT, "L9a", "CHEME-5800-L9a-Example-LinearModels-Classification-Perceptron-Fall-2026.ipynb")
        notebook = JSON.parsefile(path)
        workspace = Module(:L9aNotebookValidation)
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
        @test occursin("Include.jl", sources[1])
        for (index, source) in enumerate(sources)
            Base.include_string(REPL.softscope, workspace, source,
                joinpath(dirname(path), "validation-cell-$(index).jl"))
        end
        w = workspace

        # The dataset and the split described in the prose -
        @test size(w.df_banknote) == (1372, 5)
        @test (count(w.y .== -1), count(w.y .== 1)) == (762, 610) # a little more than half are genuine
        @test (length(w.training.y), length(w.testing.y)) == (1097, 275)
        @test all(w.training.X[:, end] .== 1) && all(w.testing.X[:, end] .== 1) # augmented features end in 1

        # learn(...) follows the lecture pseudocode from θ = 0 with M = 0 and T = 1000 -
        θ = zeros(5)
        for t ∈ 1:1000
            mistakes = 0
            for i ∈ eachindex(w.training.y)
                x̂ = w.training.X[i, :]
                if w.training.y[i] * sum(θ .* x̂) ≤ 0
                    θ = θ .+ w.training.y[i] * x̂
                    mistakes += 1
                end
            end
            mistakes == 0 && break
        end
        @test θ == w.model.β

        # "These banknotes are not linearly separable": no θ gives every training banknote yᵢ x̂ᵢᵀθ ≥ 1 -
        lp = JuMP.Model(GLPK.Optimizer)
        JuMP.@variable(lp, ϑ[1:5])
        JuMP.@constraint(lp, [i in eachindex(w.training.y)],
            w.training.y[i] * sum(w.training.X[i, j] * ϑ[j] for j in 1:5) >= 1)
        JuMP.optimize!(lp)
        @test JuMP.termination_status(lp) == JuMP.MOI.INFEASIBLE
        @test w.number_of_training_mistakes > 0

        # Every prediction is ±1, and the counts agree with each other -
        @test all(abs.(w.ŷ_banknote) .== 1)
        @test sum(w.confusion_matrix) == 275
        @test w.confusion_matrix[1, 2] + w.confusion_matrix[2, 1] == w.number_of_prediction_mistakes
        @test w.metrics.accuracy ≈ 1 - w.number_of_prediction_mistakes / 275
        # "a similar fraction of the testing and training banknotes" -
        @test abs(w.number_of_prediction_mistakes / 275 - w.number_of_training_mistakes / 1097) < 0.02
    end
end

@meeting "L9b" begin
    @testset "L9b Perceptron on non-linearly separable data" begin
        @testset "Reference Perceptron" begin
            # Separable: (1, 1) has label 1 and (-1, -1) has label -1; one update separates them -
            X = [1.0 1.0 1.0; -1.0 -1.0 1.0]
            result = L9bXOR.my_perceptron(X, [1.0, -1.0])
            @test result.mistakes == 0 && result.passes == 2
            @test all([1.0, -1.0] .* (X * result.θ) .> 0)
            # XOR on the corners of a square: never separable, so every pass is used -
            X = [1.0 1.0 1.0; -1.0 -1.0 1.0; 1.0 -1.0 1.0; -1.0 1.0 1.0]
            result = L9bXOR.my_perceptron(X, [-1.0, -1.0, 1.0, 1.0]; maxiter = 50)
            @test result.passes == 50 && result.mistakes > 0
            # A positive mistake threshold stops after the first pass with at most that many -
            result = L9bXOR.my_perceptron(X, [-1.0, -1.0, 1.0, 1.0]; maxiter = 50, mistakes = 10)
            @test result.passes == 1
            # The package's learn(...) gives the same parameters -
            model = learn(X, [-1.0, -1.0, 1.0, 1.0],
                build(MyPerceptronClassificationModel, (parameters = zeros(3), mistakes = 0)); maxiter = 50)
            @test L9bXOR.my_perceptron(X, [-1.0, -1.0, 1.0, 1.0]; maxiter = 50).θ == model.β
            @test_throws DimensionMismatch L9bXOR.my_perceptron(X, [1.0, -1.0])
            @test_throws ArgumentError L9bXOR.my_perceptron(X, [1.0, 0.0, 1.0, -1.0]) # labels must be ±1
        end

        @testset "Student stub" begin
            # The student file is the reference apart from its header and the three TODO steps.
            student_text = read(joinpath(WEEK_ROOT, "L9b", "src", "Compute.jl"), String)
            reference_text = read(joinpath(WEEK_ROOT, "L9b", "src", "Compute-solution.jl"), String)
            @test all(occursin("# TODO $i:", student_text) for i in 1:3)
            @test count("if false", student_text) == 2 # the blanks for TODO 1 and TODO 3
            @test occursin("θ = θ;", student_text) # the blank for TODO 2
            for answer in ("y[i]*dot(x̂, θ) ≤ 0", "θ = θ + y[i]*x̂", "number_of_mistakes ≤ M")
                @test !occursin(answer, student_text) # the solution's three lines
            end
            body(text) = split(text, "module L9bXOR"; limit = 2)[2]
            before(text) = split(body(text), "# TODO 1:"; limit = 2)[1]
            after(text) = split(body(text), "# We get here only while TODO 3 is incomplete"; limit = 2)[2]
            @test before(student_text) == before(reference_text)
            @test after(student_text) == after(reference_text)
            student_module = Module(:L9bStudent)
            Base.include(student_module, joinpath(WEEK_ROOT, "L9b", "src", "Compute.jl"))
            # Compute.jl holds only the student work; the helpers are in Utility.jl and Visualize.jl -
            @test Set(names(student_module.L9bXOR)) == Set([:L9bXOR, :my_perceptron])
            error = try
                student_module.L9bXOR.my_perceptron([1.0 1.0 1.0; -1.0 -1.0 1.0], [1.0, -1.0])
                nothing
            catch caught
                caught
            end
            @test error isa ErrorException && occursin("Oooops!", error.msg)
        end

        @testset "L9b lab notebook" begin
            # Run the actual notebook cells with the reference my_perceptron(...) in place of the stub -
            path = joinpath(WEEK_ROOT, "L9b", "CHEME-5800-L9b-Lab-XOR-Fall-2026.ipynb")
            notebook = JSON.parsefile(path)
            workspace = Module(:L9bNotebookValidation)
            Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
            sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
            @test occursin("Include.jl", sources[1])
            @test all(isempty(cell["outputs"]) for cell in notebook["cells"] if cell["cell_type"] == "code")
            for (index, source) in enumerate(sources)
                Base.include_string(REPL.softscope, workspace, source,
                    joinpath(dirname(path), "validation-cell-$(index).jl"))
                if index == 1 # the setup cell loaded the stub; replace it with the reference
                    Base.include(workspace, joinpath(WEEK_ROOT, "L9b", "src", "Compute-solution.jl"))
                end
            end
            w = workspace

            # The three datasets share their points and differ only in the labels -
            @test w.datasets["half circle"][:, 1:2] == w.datasets["wedge"][:, 1:2] == w.datasets["XOR"][:, 1:2]

            # Only the half-circle model separates its training data -
            for (pattern, separable) in (("half circle", true), ("wedge", false), ("XOR", false))
                D = w.training[pattern]
                X = [D[:, 1:2] ones(size(D, 1))]
                mistakes = count(D[:, 3] .* (X * w.perceptron_models[pattern].β) .<= 0)
                @test (mistakes == 0) == separable
                @test w.my_results[pattern].θ == w.perceptron_models[pattern].β
            end

            # The numbers quoted in the notebook prose -
            @test (w.my_results["wedge"].mistakes, w.my_results["XOR"].mistakes) == (234, 610)
            @test w.CM_perceptron["half circle"] == [399 1; 0 400] # [TP FN; FP TN]
            @test w.CM_perceptron["wedge"] == [62 131; 4 603]
            @test w.CM_perceptron["XOR"] == [203 207; 207 183]
            @test count(w.test["wedge"][:, 3] .== -1) == 607 # predicting -1 everywhere: 607/800 = 0.759
        end
    end
end

@meeting "L9d" begin
    @testset "L9d logistic regression on the banknotes" begin
        @testset "Reference gradient descent" begin
            # Five points on a line; no threshold separates the labels, so the loss has a minimizer -
            X = [-2.0 1.0; -1.0 1.0; 0.0 1.0; 1.0 1.0; 2.0 1.0]
            y = [-1, 1, -1, 1, 1]
            L = opnorm(X)^2
            # One step from θ = 0: σ(0) = 1/2, so ∇J = -β Xᵀy and the step gives αβ Xᵀy -
            result = L9dLogistic.my_logistic_regression(X, y; α = 1 / L, maxiter = 1)
            @test result.iterations == 1 && !result.converged
            @test result.θ ≈ (X' * y) / L
            @test result.losses[1] ≈ 5 * log(2) && length(result.losses) == 2
            # At a converged answer the central-difference gradient of the loss vanishes -
            for δ in (0.0, 1.0)
                result = L9dLogistic.my_logistic_regression(X, y; α = 1 / (L + δ), δ = δ, ϵ = 1e-10, maxiter = 200_000)
                @test result.converged
                @test all(diff(result.losses) .≤ 1e-12)
                J(θ) = L9dLogistic.regularized_loss(X, y, θ; δ = δ)
                h = 1e-6
                g = [(J(result.θ + h * e) - J(result.θ - h * e)) / (2h) for e in eachcol(Matrix(1.0I, 2, 2))]
                @test norm(g) < 1e-6
            end
            # β enters only through βθ, so with δ = 0 halving β doubles the answer -
            one = L9dLogistic.my_logistic_regression(X, y; α = 1 / L, ϵ = 1e-12, maxiter = 400_000)
            half = L9dLogistic.my_logistic_regression(X, y; α = 1 / (0.25 * L), β = 0.5, ϵ = 1e-12, maxiter = 400_000)
            @test half.θ ≈ 2 * one.θ rtol = 1e-6
            @test_throws DimensionMismatch L9dLogistic.my_logistic_regression(X, y[1:4]; α = 0.1)
            @test_throws ArgumentError L9dLogistic.my_logistic_regression(X, [-1, 1, 0, 1, 1]; α = 0.1)
            @test_throws ArgumentError L9dLogistic.my_logistic_regression(X, y; α = 0.0)
            @test_throws ArgumentError L9dLogistic.my_logistic_regression(X, y; α = 0.1, δ = -1.0)
            @test_throws ArgumentError L9dLogistic.my_logistic_regression(X, y; α = 0.1, maxiter = 0)
        end

        @testset "Student stub" begin
            # The student file is the reference apart from its header and the three TODO steps.
            student_text = read(joinpath(WEEK_ROOT, "L9d", "src", "Compute.jl"), String)
            reference_text = read(joinpath(WEEK_ROOT, "L9d", "src", "Compute-solution.jl"), String)
            @test all(occursin("# TODO $i:", student_text) for i in 1:3)
            @test occursin("∇J = ∇J;", student_text) # the blank for TODO 1
            @test occursin("θ_new = θ;", student_text) # the blank for TODO 2
            @test count("if false", student_text) == 1 # the blank for TODO 3
            for answer in ("2*β*(1 - σ(u))*y[i]*x̂", "θ - α*∇J", "change ≤ ϵ ||")
                @test !occursin(answer, student_text) # the solution's three lines
            end
            body(text) = split(text, "module L9dLogistic"; limit = 2)[2]
            before(text) = split(body(text), "# TODO 1:"; limit = 2)[1]
            after(text) = split(body(text), "# We get here only while TODO 3 is incomplete"; limit = 2)[2]
            @test before(student_text) == before(reference_text)
            @test after(student_text) == after(reference_text)
            student_module = Module(:L9dStudent)
            Base.include(student_module, joinpath(WEEK_ROOT, "L9d", "src", "Compute.jl"))
            # Compute.jl holds only the student work; the figure is in Visualize.jl -
            @test Set(names(student_module.L9dLogistic)) == Set([:L9dLogistic, :my_logistic_regression])
            error = try
                student_module.L9dLogistic.my_logistic_regression([1.0 1.0; -1.0 1.0], [1, -1]; α = 0.1, maxiter = 10)
                nothing
            catch caught
                caught
            end
            @test error isa ErrorException && occursin("Oooops!", error.msg)
        end

        @testset "L9d lab notebook" begin
            # Run the actual notebook cells with the reference solution in place of the stub -
            path = joinpath(WEEK_ROOT, "L9d", "CHEME-5800-L9d-Lab-LogisticRegression-Banknotes-Fall-2026.ipynb")
            notebook = JSON.parsefile(path)
            workspace = Module(:L9dNotebookValidation)
            Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
            sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
            @test occursin("Include.jl", sources[1])
            @test all(isempty(cell["outputs"]) for cell in notebook["cells"] if cell["cell_type"] == "code")
            for (index, source) in enumerate(sources)
                Base.include_string(REPL.softscope, workspace, source,
                    joinpath(dirname(path), "validation-cell-$(index).jl"))
                if index == 1 # the setup cell loaded the stub; replace it with the reference
                    Base.include(workspace, joinpath(WEEK_ROOT, "L9d", "src", "Compute-solution.jl"))
                end
            end
            w = workspace

            # The same split as the L9a example, standardized with training statistics only -
            data = MyBanknoteAuthenticationDataset()
            Xraw = Matrix(data[:, Not(:class)])
            yraw = Vector(data[:, :class])
            rows = randperm(MersenneTwister(1234), 1372)
            train, test = rows[1:1097], rows[1098:end]
            @test (w.training.y, w.testing.y) == (yraw[train], yraw[test])
            m, s = mean(Xraw[train, :], dims = 1), std(Xraw[train, :], dims = 1)
            @test w.testing.X ≈ [(Xraw[test, :] .- m) ./ s ones(275)]
            @test maximum(abs, mean(w.training.X[:, 1:4], dims = 1)) < 1e-12
            @test maximum(abs, std(w.training.X[:, 1:4], dims = 1) .- 1) < 1e-12
            @test 2.7 < maximum(s) / minimum(s) < 3 # "almost three times"

            # Task 1: the numbers quoted in the prose -
            r = w.result
            @test r.iterations == 50_000 && !r.converged
            @test r.losses[1] ≈ 1097 * log(2) && r.losses[2] < 500
            @test all(diff(r.losses) .≤ 1e-9)
            @test round(Int, r.losses[1001]) == 33 && round(r.losses[end], digits = 1) == 20.4
            @test count(w.training.y .* (w.training.X * r.θ) .<= 0) == 9

            # Task 2: confusion matrices [TP FN; FP TN], the misses, and the one-more-step what-ifs -
            @test confusion(w.testing.y, w.ŷ_logistic) == [128 2; 0 145]
            @test confusion(w.testing.y, w.ŷ_perceptron) == [126 4; 1 144]
            misses = findall(w.ŷ_logistic .!= w.testing.y)
            @test all(w.testing.y[misses] .== 1)
            @test round.(w.P_logistic[misses], digits = 2) == [0.29, 0.33]
            @test count(w.P_logistic .< 0.01) + count(w.P_logistic .> 0.99) == 254
            perceptron(X, T) = learn(X, w.training.y,
                build(MyPerceptronClassificationModel, (parameters = zeros(5), mistakes = 0)); maxiter = T)
            ŷ = classify(w.testing.X, perceptron(w.training.X, 1001))
            ŷ[ŷ .== 0] .= 1
            @test count(ŷ .!= w.testing.y) == 7
            Xraw_train = [Xraw[train, :] ones(1097)] # the L9a example's raw features
            @test count(classify([Xraw[test, :] ones(275)], learn(Xraw_train, w.training.y,
                build(MyPerceptronClassificationModel, (parameters = zeros(5), mistakes = 0)); maxiter = 1000)) .!= w.testing.y) == 12
            longer = L9dLogistic.my_logistic_regression(w.training.X, w.training.y;
                α = w.α, β = w.β, δ = w.δ, ϵ = w.ϵ, maxiter = 50_001)
            @test norm(longer.θ - r.θ) < 1e-4
            @test sign.(w.testing.X * longer.θ) == sign.(w.testing.X * r.θ)

            # Task 3: the inspector band -
            P = w.P_logistic
            automatic(P, band) = findall(p -> p <= band[1] || p >= band[2], P)
            label(P) = [p >= 0.5 ? 1 : -1 for p in P]
            for (band, inspected, mistakes) in (((0.25, 0.75), 5, 0), ((0.4, 0.6), 2, 2))
                @test count(p -> band[1] < p < band[2], P) == inspected
                keep = automatic(P, band)
                @test count(label(P)[keep] .!= w.testing.y[keep]) == mistakes
            end
            @test all(w.testing.y[findall(p -> 0.4 < p < 0.6, P)] .== -1) # "only 2 genuine banknotes"
            strong = L9dLogistic.my_logistic_regression(w.training.X, w.training.y;
                α = 1 / (w.L + 10.0), β = w.β, δ = 10.0, ϵ = w.ϵ, maxiter = w.maxiter)
            @test strong.converged && strong.iterations < 700
            Ps = w.P_strong
            @test count(label(Ps) .!= w.testing.y) == 6
            @test count(p -> 0.25 < p < 0.75, Ps) == 12
            @test count(Ps .< 0.01) + count(Ps .> 0.99) == 76 # "Fewer probabilities sit near 0 or 1"
            keep = automatic(Ps, (0.25, 0.75))
            @test count(label(Ps)[keep] .!= w.testing.y[keep]) == 0
        end
    end
end
