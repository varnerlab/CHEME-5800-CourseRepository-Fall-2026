const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-11"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the notebooks whose cells the suite runs or whose links it checks
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells
import SHA   # checks the vocabulary file the L11b lab reads from code/src/data
using Test   # @testset must be defined when the file is parsed, even if no meeting that loads it is released
released("L11a") && include(joinpath(WEEK_ROOT, "L11a", "Include.jl"))
released("L11b") && include(joinpath(WEEK_ROOT, "L11b", "Include.jl"))
# L11b's reference implementation; the notebook setup loads the student file.
released("L11b") && include(joinpath(WEEK_ROOT, "L11b", "src", "Compute-solution.jl"))
released("L11c") && include(joinpath(WEEK_ROOT, "L11c", "Include.jl"))
released("L11d") && include(joinpath(WEEK_ROOT, "L11d", "Include.jl"))
# L11d's reference implementation; the notebook setup loads the student file.
released("L11d") && include(joinpath(WEEK_ROOT, "L11d", "src", "Compute-solution.jl"))

# The L11a and L11c lectures carry no code. Check that every local file a notebook links or
# shows (figures, the example, the lab) exists, and that nothing links out of the week.
function check_local_links(meeting::AbstractString, notebook::AbstractString; markdown_only::Bool = true)
    path = joinpath(WEEK_ROOT, meeting, notebook)
    cells = JSON.parsefile(path)["cells"]
    markdown_only && @test all(cell["cell_type"] == "markdown" for cell in cells)
    text = join((join(cell["source"]) for cell in cells if cell["cell_type"] == "markdown"), "\n")
    targets = vcat([m.captures[1] for m in eachmatch(r"\]\(([^)\s]+)\)", text)],
        [m.captures[1] for m in eachmatch(r"src=\"([^\"]+)\"", text)])
    local_targets = filter(t -> !startswith(t, "http") && !startswith(t, "#"), targets)
    for target in local_targets
        @test isfile(normpath(joinpath(dirname(path), target)))
        @test startswith(normpath(joinpath(dirname(path), target)), WEEK_ROOT) # no links into other weeks
    end
    return length(local_targets)
end

@meeting "L11a" begin
    @testset "L11a lecture and example" begin
        @test check_local_links("L11a", "CHEME-5800-L11a-Lecture-MarkovModels-Fall-2026.ipynb") ≥ 3
        example = "CHEME-5800-L11a-Example-MarkovModels-Fall-2026.ipynb"
        @test check_local_links("L11a", example; markdown_only = false) ≥ 3

        # The example ships with outputs, none of them errors -
        path = joinpath(WEEK_ROOT, "L11a", example)
        notebook = JSON.parsefile(path)
        code_cells = [cell for cell in notebook["cells"] if cell["cell_type"] == "code"]
        @test count(cell -> !isempty(cell["outputs"]), code_cells) ≥ 10
        @test all(output["output_type"] != "error" for cell in code_cells for output in cell["outputs"])

        # Run the example's cells -
        workspace = Module(:L11aExampleValidation)
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        for (index, cell) in enumerate(code_cells)
            Base.include_string(REPL.softscope, workspace, join(cell["source"]),
                joinpath(dirname(path), "validation-cell-$(index).jl"))
        end
        w = workspace

        # The stationary distribution of the three-state chain is (36, 57, 38)/131 -
        π_exact = [36, 57, 38] ./ 131
        @test π_exact' * w.P ≈ π_exact'
        @test vec(w.π̄) ≈ π_exact atol = 1e-9
        @test w.rank(w.P) == 3 && w.rank(w.test) == 1 # full rank, and the large power has rank one
        @test all(w.test[i, :] ≈ π_exact for i in 1:3)
        # "Our chain is irreducible ... and aperiodic": every state reaches every other, and every p_ii > 0 -
        @test all((w.P^2)[i, j] + w.P[i, j] > 0 for i in 1:3, j in 1:3) && all(w.P[i, i] > 0 for i in 1:3)
        # The simulated frequencies are close to the stationary distribution (20,000 steps) -
        visits = [count(w.simulation_dict[t] == s for t in 1:w.number_of_simulation_steps) for s in 1:3]
        @test w.number_of_simulation_steps == 20_000
        @test maximum(abs.(visits ./ w.number_of_simulation_steps .- π_exact)) < 0.03

        # The two sequences have similar state frequencies but different consecutive pairs -
        independent_visits = [count(==(s), w.stationary_samples) for s in 1:3]
        @test maximum(abs.(independent_visits ./ length(w.stationary_samples) .- π_exact)) < 0.03
        @test sum(w.chain_transition_counts) == w.number_of_simulation_steps - 1
        @test sum(w.independent_transition_counts) == length(w.stationary_samples) - 1
        @test all(w.chain_transition_counts[w.P .== 0] .== 0)
        @test w.independent_transition_counts[1, 3] > 0 && w.independent_transition_counts[3, 1] > 0
        estimated_P = w.chain_transition_counts ./ sum(w.chain_transition_counts; dims = 2)
        @test maximum(abs.(estimated_P .- w.P)) < 0.03
        @test w.independent_transition_counts[1, 3] / (length(w.stationary_samples) - 1) ≈ π_exact[1] * π_exact[3] atol = 0.02

        # Repeated row updates agree with the initial condition and the stationary limit -
        @test collect(w.transient_distributions[1, 2:4]) == [0.0, 0.0, 1.0]
        @test collect(w.transient_distributions[end, 2:4]) ≈ π_exact atol = 1e-9
        @test vec(w.π̄ * w.P) ≈ vec(w.π̄) atol = 1e-11
    end
end

@meeting "L11b" begin
    @testset "L11b Markov word generator lab" begin
        @testset "Reference transition matrix" begin
            # Count by hand: "a" is too short, the '-' in "c-a" is not a state, and 'd' has no
            # two-character word, so its row stays zero -
            vocabulary = Dict('a' => Set(["a", "ab", "abc", "ac"]), 'b' => Set(["ba", "bb"]),
                'c' => Set(["ca", "c-a"]), 'd' => Set(["d"]))
            P = L11bMarkov.my_transition_matrix(vocabulary, ['a', 'b', 'c', 'd'])
            @test P ≈ [0 2/3 1/3 0; 1/2 1/2 0 0; 1 0 0 0; 0 0 0 0]
            # Only the second character counts, not the later ones -
            P = L11bMarkov.my_transition_matrix(Dict('a' => Set(["abbbb"]), 'b' => Set(["baaaa"])), ['a', 'b'])
            @test P == [0.0 1.0; 1.0 0.0]
            # The states need not be the whole alphabet -
            P = L11bMarkov.my_transition_matrix(Dict('x' => Set(["xy", "xz", "xq"]), 'y' => Set(["yx"])), ['x', 'y'])
            @test P == [0.0 1.0; 1.0 0.0]
        end

        @testset "Student stub" begin
            # The student file is the reference apart from its header and the three TODO lines.
            student_text = read(joinpath(WEEK_ROOT, "L11b", "src", "Compute.jl"), String)
            reference_text = read(joinpath(WEEK_ROOT, "L11b", "src", "Compute-solution.jl"), String)
            @test all(occursin("# TODO $i:", student_text) for i in 1:3)
            @test occursin("next_char = characters[1];", student_text) # the blank for TODO 1
            @test occursin("counts[i, j] = counts[i, j];", student_text) # the blank for TODO 2
            @test occursin("P[i, :] = counts[i, :];", student_text) # the blank for TODO 3
            for answer in ("next_char = word[2];", "counts[i, j] + 1", "counts[i, :] ./ N;")
                @test !occursin(answer, student_text) # the solution's lines
            end
            body(text) = split(text, "module L11bMarkov"; limit = 2)[2]
            before(text) = split(body(text), "# TODO 1:"; limit = 2)[1]
            between(text) = split(split(body(text), "# find its column"; limit = 2)[2], "# TODO 2:"; limit = 2)[1]
            middle(text) = split(split(body(text), "# Turn the counts into probabilities"; limit = 2)[2], "# TODO 3:"; limit = 2)[1]
            after(text) = split(body(text), "# We get here after counting every word."; limit = 2)[2]
            @test before(student_text) == before(reference_text)
            @test between(student_text) == between(reference_text)
            @test middle(student_text) == middle(reference_text)
            @test after(student_text) == after(reference_text)
            student_module = Module(:L11bStudent)
            Base.include(student_module, joinpath(WEEK_ROOT, "L11b", "src", "Compute.jl"))
            # Compute.jl holds only the student work -
            @test Set(names(student_module.L11bMarkov)) == Set([:L11bMarkov, :my_transition_matrix])
            stub_error = try
                Base.invokelatest(student_module.L11bMarkov.my_transition_matrix,
                    Dict('a' => Set(["ab"]), 'b' => Set(["ba"])), ['a', 'b'])
                nothing
            catch caught
                caught
            end
            @test stub_error isa ErrorException && occursin("Oooops!", stub_error.msg)
        end

        @testset "Vocabulary file" begin
            # dwyl/english-words words_dictionary.json (The Unlicense), as vendored on 2026-10-11 -
            path = joinpath(WEEK_ROOT, "..", "..", "code", "src", "data", "words_dictionary.json")
            @test bytes2hex(open(SHA.sha256, path)) == "745898d35f1087d20c0b8378ff67acc8dfa0796c103bfae8b0345ce1546cb5be"
        end

        @testset "L11b lab notebook" begin
            # Run the actual notebook cells with the reference solution in place of the stub -
            path = joinpath(WEEK_ROOT, "L11b", "CHEME-5800-L11b-Lab-MarkovWordGenerator-Fall-2026.ipynb")
            notebook = JSON.parsefile(path)
            workspace = Module(:L11bNotebookValidation)
            Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
            sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
            @test occursin("Include.jl", sources[1])
            @test all(isempty(cell["outputs"]) for cell in notebook["cells"] if cell["cell_type"] == "code")
            for (index, source) in enumerate(sources)
                Base.invokelatest(Base.include_string, REPL.softscope, workspace, source,
                    joinpath(dirname(path), "validation-cell-$(index).jl"))
                if index == 1 # the setup cell loaded the stub; replace it with the reference
                    Base.include(workspace, joinpath(WEEK_ROOT, "L11b", "src", "Compute-solution.jl"))
                end
            end
            w = workspace
            V = w.vocabulary_data_dictionary

            # Data: "approximately 370K English words", "> 25000 words that start with 'a'" -
            @test sum(length, values(V)) == 370_100
            @test length(V['a']) > 25_000

            # Task 1: our matrix is the package's, and the numbers the prose quotes -
            @test w.characters == collect('a':'z')
            @test w.P == vocabulary_transition_matrix(V, w.characters)
            p(a, b) = round(w.P[findfirst(==(a), w.characters), findfirst(==(b), w.characters)], digits = 3)
            @test round(w.P[2, 18], digits = 4) == 0.1395 # 'b' -> 'r'
            @test [w.characters[argmax(w.P[i, :])] for i in [17, 21, 14, 18]] == ['u', 'n', 'o', 'e']
            @test (p('q', 'u'), p('u', 'n'), p('n', 'o'), p('r', 'e')) == (0.971, 0.885, 0.647, 0.614)

            # Task 2: "828 of the 1,000 words are different from each other" -
            @test (w.seed, w.number_of_samples, w.length_of_sample_word, w.sample_word_start_char) == (5800, 1000, 6, 'b')
            @test length(w.generated_words_set) == 828
            @test all(length(word) == 6 && first(word) == 'b' for word in w.generated_words_set)

            # Task 3: "only 8 of the 828 different words are real, about 1 percent, from bacopa to brelan" -
            @test sort(collect(w.true_generated_words)) ==
                  ["bacopa", "balata", "binode", "binous", "bistre", "borele", "bovine", "brelan"]
            @test round(100 * 8 / 828, digits = 2) == 0.97

            # The word-length what-if: "92 of the 340 different four-character words are real, about
            # 27 percent, while no seven- or eight-character word is real" -
            rows = Tuple{Int,Int,Int}[]
            for word_length in 4:8
                Random.seed!(w.seed) # the what-if cell's seed
                S = sample_words(w.P, w.characters, number_of_samples = w.number_of_samples,
                    length_of_sample_word = word_length, startchar = w.sample_word_start_char)
                different_words = Set(values(S))
                push!(rows, (word_length, length(different_words), count(word -> word ∈ V['b'], different_words)))
            end
            @test rows == [(4, 340, 92), (5, 631, 44), (6, 828, 8), (7, 934, 0), (8, 985, 0)]
            @test round(100 * 92 / 340) == 27
        end
    end
end

@meeting "L11c" begin
    @testset "L11c lecture and worked backup" begin
        @test check_local_links("L11c", "CHEME-5800-L11c-Lecture-MarkovDecisionProcesses-Fall-2026.ipynb") ≥ 1

        # Derive the worked example from the grid geometry and outcome rewards -
        states = [(x, y) for x in 1:3 for y in 1:3 if (x, y) != (2, 2)]
        moves = Dict(:up => (0, 1), :down => (0, -1), :left => (-1, 0), :right => (1, 0))
        on_grid(c) = all(1 ≤ component ≤ 3 for component in c)
        available(s) = s == (3, 3) ? [:stay] : [a for (a, m) in moves if on_grid(s .+ m)]
        function grid_outcomes(s, a)
            s == (3, 3) && return [(1.0, s, 0.0)]
            intended = moves[a]
            perpendicular = [m for m in values(moves) if sum(m .* intended) == 0]
            outcomes = Tuple{Float64,Tuple{Int,Int},Float64}[]
            for (probability, move) in zip((0.8, 0.1, 0.1), (intended, perpendicular...))
                destination = s .+ move
                reward = destination == (2, 2) ? -5.0 : destination == (3, 3) ? 10.0 : -1.0
                next = on_grid(destination) && destination != (2, 2) ? destination : s
                push!(outcomes, (probability, next, reward))
            end
            return outcomes
        end
        backup(U, s, a) = sum(p * (r + 0.9 * U[next]) for (p, next, r) in grid_outcomes(s, a))
        U₀ = Dict(s => 0.0 for s in states)
        U₁ = Dict(s => maximum(backup(U₀, s, a) for a in available(s)) for s in states)
        U₂ = Dict(s => maximum(backup(U₁, s, a) for a in available(s)) for s in states)
        @test length(states) == 8
        @test Set(available((3, 1))) == Set([:up, :left])
        @test [U₁[s] for s in [(3, 2), (2, 1), (3, 1)]] ≈ [7.4, -1.4, -1.0]
        @test backup(U₁, (3, 1), :up) ≈ 4.112
        @test backup(U₁, (3, 1), :left) ≈ -1.432
        @test U₂[(3, 1)] ≈ 4.112
        @test U₀[(3, 3)] == U₁[(3, 3)] == U₂[(3, 3)] == 0.0
    end

    @testset "L11c random rollout example" begin
        example = "CHEME-5800-L11c-Example-RandomRollout-Fall-2026.ipynb"
        @test check_local_links("L11c", example; markdown_only = false) ≥ 3

        # The example ships with outputs, none of them errors -
        path = joinpath(WEEK_ROOT, "L11c", example)
        notebook = JSON.parsefile(path)
        code_cells = [cell for cell in notebook["cells"] if cell["cell_type"] == "code"]
        @test count(cell -> !isempty(cell["outputs"]), code_cells) ≥ 8
        @test all(output["output_type"] != "error" for cell in code_cells for output in cell["outputs"])

        # Run the example's cells -
        workspace = Module(:L11cExampleValidation)
        Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
        for (index, cell) in enumerate(code_cells)
            Base.include_string(REPL.softscope, workspace, join(cell["source"]),
                joinpath(dirname(path), "validation-cell-$(index).jl"))
        end
        w = workspace
        G = w.L11cGridWorld

        # The model is the lecture's grid world, and it reproduces the worked backup -
        @test length(w.world.squares) == 8 && w.world.terminal == Set([w.world.index[(3, 3)]])
        @test Set(w.world.actions[w.world.index[(3, 1)]]) == Set([1, 3]) # up and left
        lecture = G.build_slippery_grid(γ = 0.9)
        U₁ = [maximum(G.q_value(lecture, zeros(8), s, a) for a in lecture.actions[s]) for s in 1:8]
        @test U₁[lecture.index[(3, 2)]] ≈ 7.4 && G.q_value(lecture, U₁, lecture.index[(3, 1)], 1) ≈ 4.112

        # Value iteration converged to a fixed point, and the policy reaches the goal around the obstacle -
        @test w.solution.converged
        @test maximum(abs(w.solution.U[s] - maximum(G.q_value(w.world, w.solution.U, s, a) for a in w.world.actions[s]))
            for s in 1:8) ≤ w.ϵ
        @test [G.ACTION_NAMES[w.π_star[w.world.index[q]]] for q in [(1, 1), (1, 2), (1, 3), (2, 3), (2, 1), (3, 1), (3, 2)]] ==
            ["up", "up", "right", "right", "right", "up", "up"]

        # "The two squares next to the goal have the largest values" -
        nonterminal = [s for s in 1:8 if s ∉ w.world.terminal]
        top_two = sort(nonterminal; by = s -> -w.solution.U[s])[1:2]
        @test Set(w.world.squares[top_two]) == Set([(3, 2), (2, 3)])

        # The depth-d policy evaluation equals the mean rollout return, and the rollouts estimate it -
        @test all(w.solution.U .≥ w.U_random .- 1e-8)
        @test all(abs(w.rollout.U[s] - w.U_random_d[s]) < abs(w.rollout.U[s] - w.solution.U[s]) for s in nonterminal)
        @test sum(w.rollout.n) == w.number_of_rollouts && w.rollout.U[w.world.index[(3, 3)]] == 0.0
        @test abs(mean(w.corner_returns) - w.U_random_d[w.s₀]) ≤ 4 * std(w.corner_returns) / sqrt(length(w.corner_returns))
        # The depth-d values equal an independent enumeration of the expected rollout return -
        function enumerated_return(s, depth)
            (depth == 0 || s in w.world.terminal) && return 0.0
            return sum(sum(p * (r + w.world.γ * enumerated_return(s′, depth - 1)) for (p, s′, r) in w.world.outcomes[(s, a)])
                for a in w.world.actions[s]) / length(w.world.actions[s])
        end
        for depth in 1:4
            @test G.random_policy_values(w.world, d = depth) ≈ [enumerated_return(s, depth) for s in 1:8]
        end

        # "The rollouts never read T or R": the same seeded rollouts in a world whose T and R are unusable -
        blind = G.SlipperyGridWorld(w.world.squares, w.world.index, w.world.actions, w.world.terminal,
            w.world.outcomes, fill(NaN, size(w.world.T)), fill(NaN, size(w.world.R)), w.world.γ)
        @test G.random_rollout(blind, w.MersenneTwister(w.seed), w.number_of_rollouts, w.d).U == w.rollout.U
    end
end

@meeting "L11d" begin
    @testset "L11d value iteration lab" begin
        @testset "Reference value iteration" begin
            # One state, one action, reward 1, γ = 1/2: U* = 2, and the change in sweep k is (1/2)^(k-1) -
            one_state = build(MyMDPProblemModel, (𝒮 = [1], 𝒜 = [1], T = ones(1, 1, 1), R = ones(1, 1), γ = 0.5))
            r = L11dValueIteration.mysolve(MyValueIterationModel(100), one_state, ϵ = 1e-6)
            @test r.converged && r.iterations == 21 # (1/2)^20 ≤ 1e-6 < (1/2)^19
            @test abs(r.U[1] - 2.0) ≤ 0.5 * 1e-6 / (1 - 0.5) # within γϵ/(1-γ) of U*
            # the iteration limit: k_max sweeps, converged = false, and a warning -
            capped = @test_logs (:warn, r"tolerance") L11dValueIteration.mysolve(MyValueIterationModel(5), one_state)
            @test capped.converged == false && capped.iterations == 5 && capped.U ≈ [2 * (1 - 0.5^5)]
            one_sweep = @test_logs (:warn,) L11dValueIteration.mysolve(MyValueIterationModel(1), one_state)
            @test one_sweep.iterations == 1 && one_sweep.U == [1.0]
            # All rewards zero: the first sweep changes nothing, so the loop stops after one sweep -
            zero_rewards = build(MyMDPProblemModel, (𝒮 = [1, 2], 𝒜 = [1, 2], T = ones(2, 2, 2) / 2, R = zeros(2, 2), γ = 0.9))
            z = L11dValueIteration.mysolve(MyValueIterationModel(10), zero_rewards)
            @test z.converged && z.iterations == 1 && z.U == [0.0, 0.0]
            # Optimal values that are all zero are a valid result, not the "unfinished" guard: one state, rewards 0 and -1 -
            zero_best = build(MyMDPProblemModel, (𝒮 = [1], 𝒜 = [1, 2], T = ones(1, 1, 2), R = [0.0 -1.0], γ = 0.9))
            zb = L11dValueIteration.mysolve(MyValueIterationModel(10), zero_best)
            @test zb.converged && zb.iterations == 1 && zb.U == [0.0]
            @test_throws ArgumentError L11dValueIteration.mysolve(MyValueIterationModel(0), one_state)
            @test_throws ArgumentError L11dValueIteration.mysolve(MyValueIterationModel(10), one_state, ϵ = 0.0)
            # A 3 × 3 grid world: same start and order as the package solve, and converged within the bound -
            nS = 9
            small = build(MyRectangularGridWorldModel, (nrows = 3, ncols = 3, rewards = Dict((3, 3) => 10.0)))
            R = [haskey(small.states, small.coordinates[s] .+ small.moves[a]) ?
                 (small.coordinates[s] .+ small.moves[a] == (3, 3) ? 10.0 : -1.0) : -100.0 for s in 1:nS, a in 1:4]
            T = zeros(nS, nS, 4)
            for s in 1:nS, a in 1:4
                next = small.coordinates[s] .+ small.moves[a]
                ok = haskey(small.states, next) && small.coordinates[s] != (3, 3)
                T[s, ok ? small.states[next] : s, a] = 1.0
            end
            grid = build(MyMDPProblemModel, (𝒮 = collect(1:nS), 𝒜 = collect(1:4), T = T, R = R, γ = 0.9))
            for k in 1:4
                limited = @test_logs (:warn,) L11dValueIteration.mysolve(MyValueIterationModel(k), grid, ϵ = 1e-12)
                @test limited.iterations == k && limited.U ≈ solve(MyValueIterationModel(k), grid).U
            end
            g = L11dValueIteration.mysolve(MyValueIterationModel(1000), grid, ϵ = 1e-8)
            @test g.converged
            @test maximum(abs.(g.U .- solve(MyValueIterationModel(1000), grid).U)) ≤ 0.9 * 1e-8 / (1 - 0.9) + 1e-12
            @test (@test_logs (:warn,) L11dValueIteration.mysolve(MyValueIterationModel(g.iterations - 1), grid, ϵ = 1e-8)).converged == false
        end

        @testset "Student stub" begin
            # The student file is the reference apart from its header and the three TODO steps.
            student_text = read(joinpath(WEEK_ROOT, "L11d", "src", "Compute.jl"), String)
            reference_text = read(joinpath(WEEK_ROOT, "L11d", "src", "Compute-solution.jl"), String)
            @test all(occursin("# TODO $i:", student_text) for i in 1:3)
            @test occursin("U_new[s] = NaN;", student_text) # the blank for TODO 1
            @test occursin("Δ = NaN;", student_text) # the blank for TODO 2
            @test occursin("U .= NaN;", student_text) # the blank for TODO 3
            for answer in ("maximum(lookahead(problem, U, s, a) for a ∈ problem.𝒜)", "maximum(abs.(U_new .- U))", "U .= U_new")
                @test !occursin(answer, student_text) # the solution's lines
            end
            # remove each TODO comment block and the line after it (the blank or the answer); the rest must match -
            function skeleton(text)
                kept = String[]
                in_todo = false
                for line in split(split(text, "module L11dValueIteration"; limit = 2)[2], '\n')
                    if occursin("# TODO", line)
                        in_todo = true
                    elseif in_todo && occursin(r"^\s*#", line)
                        # a continuation line of the TODO comment
                    elseif in_todo
                        in_todo = false # the blank or the answer
                    else
                        push!(kept, line)
                    end
                end
                return join(kept, '\n')
            end
            @test skeleton(student_text) == skeleton(reference_text)
            student_module = Module(:L11dStudent)
            Base.include(student_module, joinpath(WEEK_ROOT, "L11d", "src", "Compute.jl"))
            # Compute.jl holds only the student work -
            @test Set(names(student_module.L11dValueIteration)) == Set([:L11dValueIteration, :mysolve])
            stub_problem = build(MyMDPProblemModel, (𝒮 = [1], 𝒜 = [1], T = ones(1, 1, 1), R = ones(1, 1), γ = 0.5))
            stub_error = try
                student_module.L11dValueIteration.mysolve(MyValueIterationModel(10), stub_problem)
                nothing
            catch caught
                caught
            end
            @test stub_error isa ErrorException && occursin("Oooops!", stub_error.msg)
            # each blank on its own trips the guard: TODO 1 and 2 at once, TODO 3 in the second sweep -
            for (blank, answer) in (("U_new[s] = NaN;", "U_new[s] = maximum(lookahead(problem, U, s, a) for a ∈ problem.𝒜);"),
                                    ("Δ = NaN;", "Δ = maximum(abs.(U_new .- U));"), ("U .= NaN;", "U .= U_new;"))
                one_blank = Module(:L11dOneBlank)
                Base.include_string(one_blank, replace(reference_text, answer => blank))
                caught = try
                    Base.invokelatest(() -> one_blank.L11dValueIteration.mysolve(MyValueIterationModel(10), stub_problem)) # look the module up in the latest world
                    nothing
                catch e
                    e
                end
                @test caught isa ErrorException && occursin("Oooops!", caught.msg)
            end
        end

        @testset "L11d lab notebook" begin
            # Run the actual notebook cells with the reference solution in place of the stub -
            path = joinpath(WEEK_ROOT, "L11d", "CHEME-5800-L11d-Lab-ValueIterationGridWorld-Fall-2026.ipynb")
            notebook = JSON.parsefile(path)
            workspace = Module(:L11dNotebookValidation)
            Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
            sources = [join(cell["source"]) for cell in notebook["cells"] if cell["cell_type"] == "code"]
            @test occursin("Include.jl", sources[1])
            @test all(isempty(cell["outputs"]) for cell in notebook["cells"] if cell["cell_type"] == "code")
            for (index, source) in enumerate(sources)
                Base.include_string(REPL.softscope, workspace, source,
                    joinpath(dirname(path), "validation-cell-$(index).jl"))
                if index == 1 # the setup cell loaded the stub; replace it with the reference
                    Base.include(workspace, joinpath(WEEK_ROOT, "L11d", "src", "Compute-solution.jl"))
                end
            end
            w = workspace

            # Task 1: the world, and "action 1 left, action 2 right, action 3 down, action 4 up" -
            @test w.world.moves == Dict(1 => (-1, 0), 2 => (1, 0), 3 => (0, -1), 4 => (0, 1))
            @test (w.nstates, w.nactions, w.γ) == (400, 4, 0.95)
            @test w.absorbing_state_set == Set([(1, 2), (2, 2), (2, 3), (4, 5), (19, 20), (4, 3)])
            # the Task 1 question (answer sheet): 1,600 rewards, 640,000 transition probabilities, 1,600 nonzero -
            @test size(w.R) == (400, 4) && length(w.T) == 640_000 && count(!iszero, w.T) == 1600

            # Task 2: absorbing states earn nothing more, and every row of T sums to one -
            @test all(all(w.R[w.world.states[c], :] .== 0.0) for c in w.absorbing_state_set)
            @test w.R[w.world.states[(4, 4)], 3] == 100.0 && w.R[w.world.states[(19, 19)], 4] == -1000.0
            @test w.R[w.world.states[(1, 1)], 1] == -50000.0 && w.R[w.world.states[(10, 10)], 1] == -1.0
            @test all(sum(w.T[s, :, a]) ≈ 1.0 for s in w.𝒮 for a in w.𝒜)

            # Task 3: "stopped after 34 sweeps", "the two value functions are identical" -
            @test w.solution.converged && w.solution.iterations == 34
            @test maximum(abs.(w.solution.U .- w.solution_stanford.U)) == 0.0
            @test w.solution.U[w.world.states[(4, 3)]] == 0.0 && w.solution.U[w.world.states[(4, 4)]] == 100.0 # answer sheet
            # "news spreads one square per sweep ... the farthest square, 33 moves away" -
            @test maximum(abs(c[1] - 4) + abs(c[2] - 3) for c in values(w.world.coordinates)) == 33
            # the path: 33 moves, down first to (20,19), down the column x = 5, and into the station at (4,3) -
            @test w.outcome == "reached the charging station" && length(w.path) - 1 == 33
            @test w.path[2] == (20, 19) && (5, 19) ∈ w.path && (5, 4) ∈ w.path && w.path[end] == (4, 3)
            @test (20 - 4, 20 - 3) == (16, 17) # "16 squares in x and 17 in y"
            # a robot that starts in an absorbing state does not move -
            @test w.follow_policy(w.my_π, (4, 3)) == ([(4, 3)], "is already at the charging station")
            @test w.follow_policy(w.my_π, (19, 20)) == ([(19, 20)], "is already in a lava pit")

            # the γ = 0.05 what-if: 8 sweeps, left along y = 19 to the edge, then back to a visited square -
            long_run_model = MyValueIterationModel(5000)
            function run_gamma(γ_try)
                m_try = build(MyMDPProblemModel, (𝒮 = w.𝒮, 𝒜 = w.𝒜, T = w.T, R = w.R, γ = γ_try))
                s_try = L11dValueIteration.mysolve(long_run_model, m_try, ϵ = w.ϵ)
                π_try = policy(Q(m_try, s_try.U))
                return (m_try, s_try, π_try, w.follow_policy(π_try, w.startstate))
            end
            (m_low, s_low, π_low, (path_low, outcome_low)) = run_gamma(0.05)
            @test s_low.converged && s_low.iterations == 8 && outcome_low == "walks in a loop" && length(path_low) - 1 == 20
            @test path_low[2] == (20, 19) && all(p[2] == 19 for p in path_low[2:end]) && path_low[end] == (1, 19)
            # "the computed values of the moves that avoid the lava and the edge are exactly equal ... the first of them, left" -
            Q_low = Q(m_low, s_low.U)
            q = Q_low[w.world.states[(20, 19)], :]
            @test q[1] == q[3] == q[4] && π_low[w.world.states[(20, 19)]] == 1
            # "a computed value near -1.05"; the station's +100, 33 moves away, discounted 32 times -
            far = [s_low.U[s] for s in w.𝒮 if abs(w.world.coordinates[s][1] - 4) + abs(w.world.coordinates[s][2] - 3) > 10 &&
                   !(w.world.coordinates[s] ∈ w.absorbing_state_set)] # squares more than 10 moves from the station
            @test length(unique(far)) == 1 && round(far[1], digits = 2) == -1.05
            @test 1e-40 < 100 * 0.05^32 < 3e-40 && 100 * 0.05^32 < eps(1.05)
            # answer sheet: the start squares that reach the station, and the sweeps for γ = 0.5 and 0.99 -
            starts = [w.world.coordinates[s] for s in w.𝒮 if !(w.world.coordinates[s] ∈ w.absorbing_state_set)]
            @test length(starts) == 394
            @test count(w.follow_policy(π_low, c)[2] == "reached the charging station" for c in starts) == 213
            for (γ_try, sweeps) in ((0.5, 28), (0.99, 34))
                (m_try, s_try, π_try, (path_try, outcome_try)) = run_gamma(γ_try)
                @test s_try.converged && s_try.iterations == sweeps
                @test outcome_try == "reached the charging station" && length(path_try) - 1 == 33
                @test count(w.follow_policy(π_try, c)[2] == "reached the charging station" for c in starts) == 394
            end
        end
    end
end
