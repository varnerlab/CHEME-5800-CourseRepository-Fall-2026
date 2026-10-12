const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-10"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the notebooks whose cells the suite runs or whose links it checks
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells
import SHA   # checks the L10b market data cache against its README
using Test   # @testset must be defined when the file is parsed, even if no meeting that loads it is released
released("L10a") && include(joinpath(WEEK_ROOT, "L10a", "Include.jl"))
released("L10b") && include(joinpath(WEEK_ROOT, "L10b", "Include.jl"))
# L10b's reference implementation; the notebook setup loads the student file.
released("L10b") && include(joinpath(WEEK_ROOT, "L10b", "src", "Compute-solution.jl"))
released("L10c") && include(joinpath(WEEK_ROOT, "L10c", "Include.jl"))
released("L10d") && include(joinpath(WEEK_ROOT, "L10d", "Include.jl"))
# L10d's reference implementation; the notebook setup loads the student file.
released("L10d") && include(joinpath(WEEK_ROOT, "L10d", "src", "Compute-solution.jl"))

# The L10a and L10c lectures carry no code. Check that every local file they link or
# show (figures, and the lab in the same meeting) exists, and that nothing links out of the week.
function check_lecture_links(meeting::AbstractString, notebook::AbstractString)
    path = joinpath(WEEK_ROOT, meeting, notebook)
    cells = JSON.parsefile(path)["cells"]
    @test all(cell["cell_type"] == "markdown" for cell in cells)
    text = join((join(cell["source"]) for cell in cells), "\n")
    targets = vcat([m.captures[1] for m in eachmatch(r"\]\(([^)\s]+)\)", text)],
        [m.captures[1] for m in eachmatch(r"src=\"([^\"]+)\"", text)])
    local_targets = filter(t -> !startswith(t, "http") && !startswith(t, "#"), targets)
    for target in local_targets
        @test isfile(normpath(joinpath(dirname(path), target)))
        @test startswith(normpath(joinpath(dirname(path), target)), WEEK_ROOT) # no links into other weeks
    end
    return length(local_targets)
end

@meeting "L10a" begin
    @testset "L10a lecture links" begin
        @test check_lecture_links("L10a", "CHEME-5800-L10a-Lecture-OnlineLearningAndRegret-Fall-2026.ipynb") ≥ 1
    end
    @testset "L10a four-round worked example" begin
        P = [1 1 -1; -1 1 1; -1 1 1; 1 -1 1]
        Y = [1, -1, 1, 1]
        model = build(MyBinaryWeightedMajorityAlgorithmModel,
            (ϵ = 0.5, n = 3, T = 4, expert = (i, t, d) -> P[t, i], adversary = (t, d) -> Y[t]))
        sims, weights = play(model, zeros(4, 1))
        @test weights == [1 1 1; 1 1 0.5; 1 0.5 0.25; 0.5 0.5 0.25; 0.5 0.25 0.25]
        @test sims[:, 4] == [1, 1, -1, 1]
        @test sum(sims[:, end]) == 2
        @test [count(P[:, i] .!= Y) for i in 1:3] == [1, 2, 2]
    end
end

@meeting "L10b" begin
    @testset "L10b weighted majority on the SPY experts" begin
        @testset "Reference weighted majority" begin
            # A game small enough to check by hand: three experts, four rounds, ϵ = 1/2 -
            P = [1 1 -1; -1 1 1; 1 -1 0; 1 1 1] # expert predictions, one row per round
            Y = [1, 1, -1, -1] # the actual outcomes
            data = zeros(4, 1) # the experts and adversary below ignore it
            hand_expert(i::Int, t::Int, d::Array{Float64,2})::Int = P[t, i]
            hand_adversary(t::Int, d::Array{Float64,2})::Int = Y[t]
            model = build(MyBinaryWeightedMajorityAlgorithmModel,
                (ϵ = 0.5, n = 3, T = 4, expert = hand_expert, adversary = hand_adversary))
            (sims, weights) = L10bWMA.my_weighted_majority(model, data)
            # round 3: expert 3 predicts 0 (no change), counts toward neither side, and is wrong -
            @test sims == [1 1 -1 1 1 0; -1 1 1 1 1 0; 1 -1 0 -1 -1 0; 1 1 1 1 -1 1]
            @test weights == [1 1 1; 1 1 0.5; 0.5 1 0.5; 0.25 1 0.25; 0.125 0.5 0.125]
            @test (sims, weights) == play(model, data)

            # A tie goes to -1, as in the course package -
            tie = build(MyBinaryWeightedMajorityAlgorithmModel, (ϵ = 0.5, n = 2, T = 1,
                expert = (i, t, d) -> (i == 1 ? 1 : -1), adversary = (t, d) -> 1))
            (tie_sims, _) = L10bWMA.my_weighted_majority(tie, zeros(1, 1))
            @test tie_sims[1, 3] == -1 && tie_sims[1, end] == 1
            @test tie_sims == play(tie, zeros(1, 1))[1]
        end

        @testset "Student stub" begin
            # The student file is the reference apart from its header and the three TODO lines.
            student_text = read(joinpath(WEEK_ROOT, "L10b", "src", "Compute.jl"), String)
            reference_text = read(joinpath(WEEK_ROOT, "L10b", "src", "Compute-solution.jl"), String)
            @test all(occursin("# TODO $i:", student_text) for i in 1:3)
            @test occursin("ŷ = 0;", student_text) # the blank for TODO 1
            @test occursin("mistake = 0;", student_text) # the blank for TODO 2
            @test occursin("weights[t+1, i] = weights[t, i];", student_text) # the blank for TODO 3
            for answer in ("(weight_up > weight_down) ? 1 : -1", "(predictions[i] == y) ? 0 : 1", "*(1 - ϵ*mistake)")
                @test !occursin(answer, student_text) # the solution's three lines
            end
            body(text) = split(text, "module L10bWMA"; limit = 2)[2]
            before(text) = split(body(text), "# TODO 1:"; limit = 2)[1]
            middle(text) = split(split(body(text), "# Our prediction must be 1 or -1"; limit = 2)[2], "# TODO 2:"; limit = 2)[1]
            after(text) = split(body(text), "# Record this round"; limit = 2)[2]
            @test before(student_text) == before(reference_text)
            @test middle(student_text) == middle(reference_text)
            @test after(student_text) == after(reference_text)
            student_module = Module(:L10bStudent)
            Base.include(student_module, joinpath(WEEK_ROOT, "L10b", "src", "Compute.jl"))
            # Compute.jl holds only the student work -
            @test Set(names(student_module.L10bWMA)) == Set([:L10bWMA, :my_weighted_majority])
            stub_model = build(MyBinaryWeightedMajorityAlgorithmModel,
                (ϵ = 0.5, n = 1, T = 1, expert = (i, t, d) -> 1, adversary = (t, d) -> 1))
            error = try
                student_module.L10bWMA.my_weighted_majority(stub_model, zeros(1, 1))
                nothing
            catch caught
                caught
            end
            @test error isa ErrorException && occursin("Oooops!", error.msg)
        end

        @testset "Market data cache" begin
            # The SHA-256 quoted in data/README.md -
            path = joinpath(WEEK_ROOT, "L10b", "data", "SP500-Daily-VWAP-1-3-2014-to-12-31-2024.csv")
            @test bytes2hex(open(SHA.sha256, path)) == "6fc16374b3fc06dc1b9318a9fcb1056944fbe939f7a4674f1ed70e05a10c25ae"
            readme = read(joinpath(WEEK_ROOT, "L10b", "data", "README.md"), String)
            @test occursin("6fc16374b3fc06dc1b9318a9fcb1056944fbe939f7a4674f1ed70e05a10c25ae", readme)
        end

        @testset "L10b lab notebook" begin
            # Run the actual notebook cells with the reference solution in place of the stub -
            path = joinpath(WEEK_ROOT, "L10b", "CHEME-5800-L10b-Lab-WeightedMajorityAlgorithm-Fall-2026.ipynb")
            notebook = JSON.parsefile(path)
            workspace = Module(:L10bNotebookValidation)
            Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
            sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
            @test occursin("Include.jl", sources[1])
            @test all(isempty(cell["outputs"]) for cell in notebook["cells"] if cell["cell_type"] == "code")
            for (index, source) in enumerate(sources)
                Base.include_string(REPL.softscope, workspace, source,
                    joinpath(dirname(path), "validation-cell-$(index).jl"))
                if index == 1 # the setup cell loaded the stub; replace it with the reference
                    Base.include(workspace, joinpath(WEEK_ROOT, "L10b", "src", "Compute-solution.jl"))
                end
            end
            w = workspace

            # The data: 424 complete tickers, 2,767 days, so 2,766 growth rates -
            @test length(w.list_of_tickers) == 424
            @test size(w.growth_rate_array) == (2766, 424)
            @test all(nrow(w.dataset[ticker]) == 2767 for ticker in w.list_of_tickers)

            # Task 1: "in round 4 all five predicted down while SPY went up" -
            @test all(w.expert(i, 4, w.growth_rate_array) == -1 for i in 1:5)
            @test w.adversary(4, w.growth_rate_array) == 1

            # Task 2: the notebook's game matches the course package, and the quoted numbers -
            @test (w.sims, w.weights) == play(w.model, w.growth_rate_array)
            actual = w.sims[:, 7]
            @test [count(w.sims[:, i] .!= actual) for i in 1:5] == [40, 76, 83, 79, 91]
            @test sum(w.sims[:, end]) == 44 && round(1 - 44 / 252, digits = 3) == 0.825
            @test all(argmax(w.weights[t, :]) == 1 for t in 22:253) # "From about round 22 on"
            @test w.weights[end, 1] > 4 * maximum(w.weights[end, 2:5]) # "more than four times"
            fast = build(MyBinaryWeightedMajorityAlgorithmModel, (ϵ = 0.5, n = 5, T = 252,
                expert = w.expert, adversary = w.adversary))
            @test sum(L10bWMA.my_weighted_majority(fast, w.growth_rate_array)[1][:, end]) == 42 # answer sheet

            # Task 3: the best expert, the bound, and the forecast game -
            @test w.î == 1
            @test all(w.L .≤ w.R) && w.L[end] == 44
            @test round(Int, 2 * log(5) / w.model.ϵ) == 81 && round(Int, w.R[end]) == 164
            fa = w.forecast_sims[:, 7]
            @test sum(w.forecast_sims[:, end]) == 104
            @test argmax(w.forecast_weights[end, :]) == 4
            @test [count(w.forecast_sims[:, i] .!= fa) for i in 1:5] == [108, 110, 121, 101, 115]
            @test count(fa .!= 1) == 106 # always predicting up
            î = argmax(w.forecast_weights[end, :])
            bound = (2 * log(5) / w.model.ϵ) .+ 2 * (1 + w.model.ϵ) .* cumsum(w.forecast_sims[:, î] .!= fa)
            @test all(cumsum(w.forecast_sims[:, end]) .≤ bound)
        end
    end
end

@meeting "L10c" begin
    @testset "L10c lecture links" begin
        check_lecture_links("L10c", "CHEME-5800-L10c-Lecture-StochasticMultiarmBandits-Fall-2026.ipynb")
    end
end

@meeting "L10d" begin
    @testset "L10d bandit algorithms lab" begin
        @testset "Zero rewards and action histories" begin
            models = [MyExploreFirstAlgorithmModel, MyEpsilonGreedyAlgorithmModel, MyUCB1AlgorithmModel]
            for M in models
                # The first arm always fails; the second always succeeds -
                seen = Int[]
                world(a) = (push!(seen, a); a == 1 ? 0.0 : 1.0)
                Random.seed!(5800)
                game = solve(build(M, (K = 2,)), T = 100, world = world, return_history = true)
                @test game.actions == seen # every world call is recorded, including failures
                @test length(game.actions) == 100 && size(game.rewards) == (100, 2)
                @test count(==(2), game.actions) > 50 # regression: UCB1 previously pulled arm 1 99 times
                @test sum(game.rewards) == count(==(2), game.actions)
                @test all(iszero, game.rewards[game.actions .== 1, :])
                @test all(game.rewards[t, game.actions[t]] == (game.actions[t] == 2 ? 1.0 : 0.0) for t in 1:100)

                # The original matrix interface returns the same rewards -
                Random.seed!(5800)
                @test solve(build(M, (K = 2,)), T = 100, world = a -> a == 1 ? 0.0 : 1.0) == game.rewards

                # All-zero rewards and short horizons still have valid action records -
                zero_game = solve(build(M, (K = 2,)), T = 2, world = a -> 0.0, return_history = true)
                @test zero_game.actions == [1, 2] && all(iszero, zero_game.rewards)
                one = solve(build(M, (K = 1,)), T = 1, world = a -> 0.0, return_history = true)
                @test one.actions == [1] && one.rewards == zeros(1, 1)
                @test_throws ArgumentError solve(build(M, (K = 0,)), T = 10)
                @test_throws ArgumentError solve(build(M, (K = 3,)), T = 2)
            end
        end

        @testset "Repeated bandit experiments" begin
            # Deterministic Bernoulli arms give an exact oracle check: R = G -
            arms = [Bernoulli(0.0), Bernoulli(1.0)]
            experiment = L10dUtility.compare_bandits(arms, [20, 100], [11, 12, 13])
            @test size(experiment.gap_regrets) == (2, 3, 3)
            @test experiment.gap_regrets == experiment.realized_regrets
            @test all(0 .≤ experiment.gap_regrets .≤ 100)
            @test experiment.mean_gap == experiment.mean_realized
            @test experiment.se_gap ≈ experiment.sd_gap ./ sqrt(3)
            again = L10dUtility.compare_bandits(arms, [20, 100], [11, 12, 13])
            @test again.gap_regrets == experiment.gap_regrets
            equal = L10dUtility.compare_bandits([Bernoulli(1.0), Bernoulli(1.0)], [10], [1, 2])
            @test all(iszero, equal.gap_regrets) && all(iszero, equal.realized_regrets)
            @test_throws ArgumentError L10dUtility.compare_bandits(arms, [1], [1, 2])
            @test_throws ArgumentError L10dUtility.compare_bandits(arms, [10], [1, 1])
        end

        @testset "Reference Thompson sampling" begin
            # Arm 2 always succeeds and arm 1 always fails: every pull lands in the right count -
            rng = MersenneTwister(1)
            r = L10dThompson.my_thompson_sampling(a -> a == 2 ? 1 : 0, 2, 200; rng = rng)
            @test sum(r.S) + sum(r.F) == 200 && length(r.actions) == 200
            @test r.S == [0, count(r.actions .== 2)] && r.F == [count(r.actions .== 1), 0]
            @test r.rewards == [a == 2 ? 1 : 0 for a in r.actions]
            @test count(r.actions .== 2) > 190
            # The same seed gives the same game -
            rng = MersenneTwister(1)
            @test L10dThompson.my_thompson_sampling(a -> a == 2 ? 1 : 0, 2, 200; rng = rng).actions == r.actions
            # The prior is used: a strong prior for arm 1 keeps every pull on arm 1 while it succeeds -
            rng = MersenneTwister(2)
            r = L10dThompson.my_thompson_sampling(a -> 1, 2, 50; rng = rng, α = [50.0, 1.0], β = [1.0, 50.0])
            @test all(r.actions .== 1) && r.S == [50, 0]
            # One arm: every pull is arm 1 -
            r = L10dThompson.my_thompson_sampling(a -> 0, 1, 10; rng = MersenneTwister(3))
            @test r.actions == fill(1, 10) && r.F == [10]
            @test_throws ArgumentError L10dThompson.my_thompson_sampling(a -> 1, 0, 10; rng = MersenneTwister(1))
            @test_throws ArgumentError L10dThompson.my_thompson_sampling(a -> 1, 2, 0; rng = MersenneTwister(1))
            @test_throws ArgumentError L10dThompson.my_thompson_sampling(a -> 1, 2, 10; rng = MersenneTwister(1), α = [1.0])
            @test_throws ArgumentError L10dThompson.my_thompson_sampling(a -> 1, 2, 10; rng = MersenneTwister(1), β = [1.0, 0.0])
            @test_throws ArgumentError L10dThompson.my_thompson_sampling(a -> 2, 2, 10; rng = MersenneTwister(1))
        end

        @testset "Student stub" begin
            # The student file is the reference apart from its header and the three TODO steps.
            student_text = read(joinpath(WEEK_ROOT, "L10d", "src", "Compute.jl"), String)
            reference_text = read(joinpath(WEEK_ROOT, "L10d", "src", "Compute-solution.jl"), String)
            @test all(occursin("# TODO $i:", student_text) for i in 1:3)
            @test occursin("p[a] = 0.0;", student_text) # the blank for TODO 1
            @test occursin("aₜ = 1;", student_text) # the blank for TODO 2
            @test occursin("S[aₜ] = S[aₜ];", student_text) && occursin("F[aₜ] = F[aₜ];", student_text) # the blanks for TODO 3
            for answer in ("rand(rng, Beta(α[a] + S[a], β[a] + F[a]))", "aₜ = argmax(p)", "S[aₜ] + rₜ", "F[aₜ] + (1 - rₜ)")
                @test !occursin(answer, student_text) # the solution's lines
            end
            body(text) = split(text, "module L10dThompson"; limit = 2)[2]
            before(text) = split(body(text), "# TODO 1:"; limit = 2)[1]
            between(text) = split(split(body(text), "# Step 3:"; limit = 2)[2], "# TODO 3:"; limit = 2)[1]
            after(text) = split(body(text), "# We get here after T rounds."; limit = 2)[2]
            @test before(student_text) == before(reference_text)
            @test between(student_text) == between(reference_text)
            @test after(student_text) == after(reference_text)
            student_module = Module(:L10dStudent)
            Base.include(student_module, joinpath(WEEK_ROOT, "L10d", "src", "Compute.jl"))
            # Compute.jl holds only the student work -
            @test Set(names(student_module.L10dThompson)) == Set([:L10dThompson, :my_thompson_sampling])
            stub_error = try
                student_module.L10dThompson.my_thompson_sampling(a -> 1, 3, 10; rng = MersenneTwister(1))
                nothing
            catch caught
                caught
            end
            @test stub_error isa ErrorException && occursin("Oooops!", stub_error.msg)
        end

        @testset "L10d lab notebook" begin
            # Run the actual notebook cells with the reference solution in place of the stub -
            path = joinpath(WEEK_ROOT, "L10d", "CHEME-5800-L10d-Lab-BanditAlgorithms-Fall-2026.ipynb")
            notebook = JSON.parsefile(path)
            workspace = Module(:L10dNotebookValidation)
            Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
            sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
            @test occursin("Include.jl", sources[1])
            @test all(isempty(cell["outputs"]) for cell in notebook["cells"] if cell["cell_type"] == "code")
            for (index, source) in enumerate(sources)
                Base.include_string(REPL.softscope, workspace, source,
                    joinpath(dirname(path), "validation-cell-$(index).jl"))
                if index == 1 # the setup cell loaded the stub; replace it with the reference
                    Base.include(workspace, joinpath(WEEK_ROOT, "L10d", "src", "Compute-solution.jl"))
                end
            end
            w = workspace

            # The arms: arm 2 is best (10/12), arm 5 is the closest competitor (20/26) -
            μ = mean.(w.arms)
            @test argmax(μ) == 2 && μ[2] ≈ 10 / 12
            @test sortperm(μ, rev = true)[2] == 5 && μ[5] ≈ 20 / 26
            @test (w.K, w.T, w.seed) == (7, 5000, 5800)

            # Task 1: the exploration budget and action histories -
            @test w.N == 163 && w.K * w.N == 1141
            pulls(game) = [count(==(a), game.actions) for a in 1:w.K]
            for game in (w.game_explore_first, w.game_eps_greedy, w.game_UCB1)
                @test all(game.rewards[t, game.actions[t]] > 0 for t in 1:w.T) # these Beta rewards are positive
                @test sum(pulls(game)) == w.T
                @test argmax(pulls(game)) == 2
            end
            @test pulls(w.game_explore_first) == [163, 4022, 163, 163, 163, 163, 163]
            @test w.game_eps_greedy.actions[1:7] == collect(1:7)
            @test w.game_UCB1.actions[1:7] == collect(1:7)
            # the pull counts quoted in the Task 1 prose and question -
            @test pulls(w.game_eps_greedy)[2] == 3655 && extrema(pulls(w.game_eps_greedy)[[1, 3, 4, 5, 6, 7]]) == (212, 236)
            @test pulls(w.game_UCB1)[[2, 3, 5]] == [3518, 32, 946]
            # epsilon-greedy's capped schedule: ε_t = 1 through round 21 for K = 7 -
            @test all(t -> min(1.0, cbrt(w.K * log(t) / t)) == 1.0, (w.K + 1):21) && cbrt(w.K * log(22) / 22) < 1

            # Task 2: realized regret and the repeated experiment -
            rc = w.regret_curves
            for (label, game) in zip(["Explore-first", "ε-greedy", "UCB1"],
                [w.game_explore_first, w.game_eps_greedy, w.game_UCB1])
                @test rc[label] ≈ (1:w.T).*maximum(μ) .- cumsum(vec(sum(game.rewards, dims = 2)))
            end
            @test abs(rc["Explore-first"][end] - rc["Explore-first"][1141]) < 20 # levels off after exploring
            @test round((w.T^(2 / 3)) * (w.K * log(w.T))^(1 / 3), digits = 1) == 1142.3
            @test round(sqrt(w.K * w.T * log(w.T)), digits = 1) == 546.0
            @test [round(rc[l][end], digits = 1) for l in ["Explore-first", "ε-greedy", "UCB1"]] == [400.5, 525.7, 232.0]
            @test rc["ε-greedy"][1000] - rc["UCB1"][1000] > 25 # the two curves separate within the first thousand rounds
            ensemble = w.ensemble
            @test ensemble.horizons == [1000, 2500, 5000, 10_000]
            @test length(ensemble.seeds) == 30 && length(unique(ensemble.seeds)) == 30
            @test size(ensemble.gap_regrets) == (4, 3, 30)
            @test all(isfinite, ensemble.mean_gap) && all(ensemble.mean_gap .≥ 0)
            @test ensemble.mean_gap ≈ dropdims(mean(ensemble.gap_regrets, dims = 3), dims = 3)
            @test ensemble.se_gap ≈ ensemble.sd_gap ./ sqrt(30)
            # the averages, spreads, and growth ratios quoted in the prose -
            @test round.(ensemble.mean_gap[4, :], digits = 1) == [620.7, 872.7, 285.8]
            @test all(h -> length(unique(ensemble.gap_regrets[h, 1, :])) == 1, 1:4) # explore-first: the same gap loss in every game
            @test all(<(1e-9), ensemble.sd_gap[:, 1]) # so its standard deviation shows as 0.0
            @test all(abs.(ensemble.mean_gap .- ensemble.mean_realized) .< 5)
            @test all(ensemble.gap_regrets[:, 3, :] .< ensemble.gap_regrets[:, 1, :]) # UCB1 beats both others in every game
            @test all(ensemble.gap_regrets[:, 3, :] .< ensemble.gap_regrets[:, 2, :])
            @test round.(ensemble.mean_gap[4, :] ./ ensemble.mean_gap[3, :], digits = 2) == [1.63, 1.64, 1.30]

            # Task 3: Thompson sampling on θ = (0.90, 0.60, 0.80), and the closer arm 3 -
            r = w.result
            @test r.S .+ r.F == [4908, 11, 81]
            @test round.((1 .+ r.S) ./ (2 .+ r.S .+ r.F), digits = 3) == [0.905, 0.538, 0.819]
            rng = MersenneTwister(w.seed)
            closer = L10dThompson.my_thompson_sampling(a -> w.bernoulli_world(a, [0.90, 0.60, 0.88], rng), 3, w.T; rng = rng)
            @test (closer.S .+ closer.F)[3] == 551
        end
    end
end
