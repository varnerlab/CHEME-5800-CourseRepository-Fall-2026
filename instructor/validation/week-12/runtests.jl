const WEEK_ROOT = normpath(joinpath(@__DIR__, "..", "..", "..", "weeks", "week-12"))
include(joinpath(@__DIR__, "..", "release_scope.jl"))
import JSON  # reads the notebooks whose cells the suite runs or whose links it checks
import REPL  # REPL.softscope applies Jupyter's scoping rules to those cells
using Test   # @testset must be defined when the file is parsed, even if no meeting that loads it is released
released("L12a") && include(joinpath(WEEK_ROOT, "L12a", "Include.jl"))
released("L12b") && include(joinpath(WEEK_ROOT, "L12b", "Include.jl"))
# L12b's reference implementation; the notebook setup loads the student file.
released("L12b") && include(joinpath(WEEK_ROOT, "L12b", "src", "Compute-solution.jl"))
released("L12c") && include(joinpath(WEEK_ROOT, "L12c", "Include.jl"))
released("L12d") && include(joinpath(WEEK_ROOT, "L12d", "Include.jl"))

# Check that every local file a notebook links or shows (figures, examples, labs) exists, and
# that nothing links out of the week.
function check_local_links(meeting::AbstractString, notebook::AbstractString; markdown_only::Bool = true)
    path = joinpath(WEEK_ROOT, meeting, notebook)
    cells = JSON.parsefile(path)["cells"]
    markdown_only && @test all(cell["cell_type"] == "markdown" for cell in cells)
    text = join((join(cell["source"]) for cell in cells if cell["cell_type"] == "markdown"), "\n")
    targets = vcat([m.captures[1] for m in eachmatch(r"\]\(([^)\s]+)\)", text)],
        [m.captures[1] for m in eachmatch(r"src=\"([^\"]+)\"", text)])
    local_targets = filter(t -> !startswith(t, "http") && !startswith(t, "#"), targets)
    for target in local_targets
        @test ispath(normpath(joinpath(dirname(path), target)))
        @test startswith(normpath(joinpath(dirname(path), target)), WEEK_ROOT) # no links into other weeks
    end
    return length(local_targets)
end

# Run a notebook's code cells in a fresh module, as Jupyter would. When `solution` is given,
# it is loaded right after the setup cell, in place of the student stub.
function run_notebook(meeting::AbstractString, notebook::AbstractString, name::Symbol;
    solution::Union{Nothing,String} = nothing)
    path = joinpath(WEEK_ROOT, meeting, notebook)
    cells = [cell for cell in JSON.parsefile(path)["cells"] if cell["cell_type"] == "code"]
    workspace = Module(name)
    Core.eval(workspace, :(include(path::AbstractString) = Base.include(@__MODULE__, path)))
    for (index, cell) in enumerate(cells)
        Base.invokelatest(Base.include_string, REPL.softscope, workspace, join(cell["source"]),
            joinpath(dirname(path), "validation-cell-$(index).jl"))
        if index == 1 && solution !== nothing
            Base.include(workspace, joinpath(WEEK_ROOT, meeting, "src", solution))
        end
    end
    return (workspace, cells)
end

@testset "Week 12 manifest" begin
    # No week-level src folder, and no scaffold notebook, is left behind -
    @test !ispath(joinpath(WEEK_ROOT, "src"))
    for meeting in ("L12a", "L12b", "L12c", "L12d")
        for file in readdir(joinpath(WEEK_ROOT, meeting))
            @test !occursin("Week12Core", file) && !occursin("Tabular", file)
        end
    end
    # Every entry notebook and dataset in the manifest exists, and the README links each notebook -
    manifest = read(joinpath(WEEK_ROOT, "release.toml"), String)
    readme = read(joinpath(WEEK_ROOT, "README.md"), String)
    listed = [m.captures[1] for m in eachmatch(r"\"(L12[a-d]/[^\"]+)\"", manifest)]
    @test length(listed) == 7
    for file in listed
        @test isfile(joinpath(WEEK_ROOT, file))
        endswith(file, ".ipynb") && @test occursin(file, readme)
    end
end

@meeting "L12a" begin
    @testset "L12a lecture and example" begin
        @test check_local_links("L12a", "CHEME-5800-L12a-Lecture-QLearning-Fall-2026.ipynb") ≥ 4
        example = "CHEME-5800-L12a-Example-AdaptiveDosing-QLearning-Fall-2026.ipynb"
        @test check_local_links("L12a", example; markdown_only = false) ≥ 3

        # The example ships with outputs, none of them errors -
        shipped = [cell for cell in JSON.parsefile(joinpath(WEEK_ROOT, "L12a", example))["cells"] if cell["cell_type"] == "code"]
        @test count(cell -> !isempty(cell["outputs"]), shipped) ≥ 8
        @test all(output["output_type"] != "error" for cell in shipped for output in cell["outputs"])

        # Run the example's cells -
        (w, _) = run_notebook("L12a", example, :L12aExampleValidation)
        env = w.env

        # Task 1: 41 × 41 states, four doses, and the start (0.90, 0) -
        @test (w.nstates, w.nactions) == (1681, 4)
        @test w.decode(env, w.s₀) == (0.9, 0.0)
        # "No fixed dose cures the patient": none and low time out, medium and high are lethal -
        fixed = [w.simulate(env, fill(a, w.nstates), w.s₀) for a in 1:4]
        @test [(r.outcome, r.steps) for r in fixed] == [(:timeout, 100), (:timeout, 100), (:dead, 7), (:dead, 3)]
        # a timeout records the state after the last cycle: 101 states and 101 doses -
        @test (length(fixed[1].B), length(fixed[1].Z), length(fixed[1].dose)) == (101, 101, 101)

        # Task 2: the optimal policy cures in 13 cycles with the pulse-and-rest schedule -
        @test w.optimal.outcome == :cured && w.optimal.steps == 13
        # a cure on the last allowed cycle is a cure, not a timeout -
        at_limit = w.simulate(env, w.π_star, w.s₀; maxsteps = 13)
        @test (at_limit.outcome, at_limit.steps) == (:cured, 13) && at_limit.B == w.optimal.B && at_limit.dose == w.optimal.dose
        short_run = w.simulate(env, w.π_star, w.s₀; maxsteps = 3)
        @test (short_run.outcome, length(short_run.B), length(short_run.dose)) == (:timeout, 4, 4)
        # running out of sweeps prints a warning -
        @test_logs (:warn, r"k_max") w.solve(env; γ = 0.95, k_max = 1)
        @test round.(w.optimal.dose, digits = 2) == [1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.67, 0.33, 0.67, 0.67, 0.67, 0.0]
        # the tumor falls with each high dose and grows back during each rest (cycles 1 to 8) -
        for t in 1:8
            if w.optimal.dose[t] == 1.0
                @test w.optimal.B[t + 1] < w.optimal.B[t]
            elseif w.optimal.dose[t] == 0.0
                @test w.optimal.B[t + 1] > w.optimal.B[t]
            end
        end
        # the toxicity stays just below the lethal level -
        @test maximum(w.optimal.Z) == 0.875 && maximum(w.optimal.Z) < env.Zlethal

        # Task 3: the learned policy gives the same doses from the start -
        @test w.learned.outcome == :cured && w.learned.dose == w.optimal.dose
        @test all(w.agent.Q[s, :] == zeros(4) for s in 1:w.nstates if w.isterminal(env, s)) # absorbing rows stay zero
        # absorbing rows are set to zero even when the starting table is not zero -
        hundreds = build(MyQLearningAgentModel, (states = collect(1:w.nstates), actions = collect(1:4), α = 0.1, γ = 0.95,
            Q = fill(100.0, w.nstates, 4)))
        hundreds = w.solve(hundreds, env; episodes = 10, maxsteps = 5, seed = 1)
        @test all(hundreds.Q[s, :] == zeros(4) for s in 1:w.nstates if w.isterminal(env, s))
        # Benchmark: 71 visited states, 53 the same (about three quarters), values 20.2 to 60, largest loss about 3 -
        visited = Set{Int64}()
        for B₀ in 0.10:0.05:0.95
            s = w.stateindex(env, B₀, 0.0)
            for t in 1:100
                w.isterminal(env, s) && break
                push!(visited, s)
                (s, _) = w.world(env, s, w.π_star[s])
            end
        end
        same = count(s -> w.π_q[s] == w.π_star[s], visited)
        optimal_values = [w.Qstar[s, w.π_star[s]] for s in visited]
        losses = [w.Qstar[s, w.π_star[s]] - w.Qstar[s, w.π_q[s]] for s in visited if w.π_q[s] != w.π_star[s]]
        @test (length(visited), same) == (71, 53)
        @test round.((minimum(optimal_values), maximum(optimal_values)), digits = 1) == (20.2, 60.0)
        @test round(maximum(losses), digits = 2) == 3.13
        # Four starts: both cure, and the learned policy takes at most one more cycle -
        rows = [(w.simulate(env, w.π_star, w.stateindex(env, B₀, 0.0)), w.simulate(env, w.π_q, w.stateindex(env, B₀, 0.0)))
                for B₀ in (0.30, 0.50, 0.70, 0.90)]
        @test [(a.steps, b.steps) for (a, b) in rows] == [(6, 7), (9, 9), (12, 13), (13, 13)]
        @test all(a.outcome == :cured && b.outcome == :cured for (a, b) in rows)
    end
end

@meeting "L12b" begin
    @testset "L12b Q-learning lab" begin
        # the three-state problem of the notebook's check cell -
        T_small = zeros(3, 3, 2)
        R_small = zeros(3, 2)
        T_small[1, 2, 1] = 1.0; R_small[1, 1] = -1.0
        T_small[1, 1, 2] = 1.0; R_small[1, 2] = -2.0
        T_small[2, 3, 1] = 1.0; R_small[2, 1] = 10.0
        T_small[2, 1, 2] = 1.0; R_small[2, 2] = -1.0
        T_small[3, 3, 1] = 1.0; T_small[3, 3, 2] = 1.0
        small = build(MyMDPProblemModel, (𝒮 = [1, 2, 3], 𝒜 = [1, 2], T = T_small, R = R_small, γ = 0.9))
        one_step_agent() = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2],
            α = 0.5, γ = 0.5, Q = [0.0 4.0; 0.0 0.0; 0.0 0.0]))
        other_agent() = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2],
            α = 0.25, γ = 0.5, Q = [6.0 4.0; 0.0 0.0; 0.0 0.0]))
        # the expectations of the notebook's check cell; true when a myqlearning(...) passes all three -
        function passes_check(f)
            one_step = Base.invokelatest(f, one_step_agent(), small; worldmodel = lavaworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ = 0.0)
            other_step = Base.invokelatest(f, other_agent(), small; worldmodel = lavaworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ = 0.0)
            agent = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 1.0, γ = 0.9, Q = zeros(3, 2)))
            exact = Base.invokelatest(f, agent, small; worldmodel = lavaworld,
                absorbing = Set([3]), episodes = 500, maxsteps = 50, ϵ = 1.0)
            return one_step.visits == [0 1; 0 0; 0 0] && one_step.Q ≈ [0.0 2.0; 0.0 0.0; 0.0 0.0] &&
                   other_step.visits == [1 0; 0 0; 0 0] && other_step.Q ≈ [4.25 4.0; 0.0 0.0; 0.0 0.0] &&
                   exact.Q ≈ [8.0 5.2; 10.0 6.2; 0.0 0.0]
        end

        @testset "Reference Q-learning" begin
            one_step = L12bQLearning.myqlearning(one_step_agent(), small; worldmodel = lavaworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ = 0.0)
            @test one_step.visits == [0 1; 0 0; 0 0]
            @test one_step.Q ≈ [0.0 2.0; 0.0 0.0; 0.0 0.0]
            @test passes_check(L12bQLearning.myqlearning)
            # absorbing rows are set to zero even when the starting table is not zero -
            hundreds = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 1.0, γ = 0.9, Q = fill(100.0, 3, 2)))
            from_hundreds = L12bQLearning.myqlearning(hundreds, small; worldmodel = lavaworld,
                absorbing = Set([3]), episodes = 500, maxsteps = 50, ϵ = 1.0)
            @test from_hundreds.Q ≈ [8.0 5.2; 10.0 6.2; 0.0 0.0]
            agent = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 1.0, γ = 0.9, Q = zeros(3, 2)))
            exact = L12bQLearning.myqlearning(agent, small; worldmodel = lavaworld,
                absorbing = Set([3]), episodes = 500, maxsteps = 50, ϵ = 1.0)
            @test exact.Q ≈ [8.0 5.2; 10.0 6.2; 0.0 0.0]
            @test agent.Q == zeros(3, 2) # the agent's own table is not changed
            # the same seed gives the same table -
            again = L12bQLearning.myqlearning(agent, small; worldmodel = lavaworld,
                absorbing = Set([3]), episodes = 500, maxsteps = 50, ϵ = 1.0)
            @test again.Q == exact.Q && again.visits == exact.visits
        end

        @testset "Student stub" begin
            # The student file is the reference apart from its header and the three TODO lines.
            student_text = read(joinpath(WEEK_ROOT, "L12b", "src", "Compute.jl"), String)
            reference_text = read(joinpath(WEEK_ROOT, "L12b", "src", "Compute-solution.jl"), String)
            @test all(occursin("# TODO $i:", student_text) for i in 1:3)
            @test occursin("target = NaN;", student_text) && occursin("Q[s,a] = NaN;", student_text)
            for answer in ("argmax(Q[s,:])", "r + γ*maximum(Q[s′,:])", "Q[s,a] + α*(target - Q[s,a])")
                @test !occursin(answer, student_text) # the solution's lines
                @test occursin(answer, reference_text)
            end
            # every TODO has a Hint -
            @test count("Hint:", student_text) == 3
            # remove each TODO comment block and the line after it (the blank or the answer); the rest must match -
            function skeleton(text)
                kept = String[]
                in_todo = false
                for line in split(split(text, "module L12bQLearning"; limit = 2)[2], '\n')
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
            student_module = Module(:L12bStudent)
            Base.include(student_module, joinpath(WEEK_ROOT, "L12b", "src", "Compute.jl"))
            # Compute.jl holds only the student work -
            @test Set(names(student_module.L12bQLearning)) == Set([:L12bQLearning, :myqlearning])
            stub_error = try
                Base.invokelatest(student_module.L12bQLearning.myqlearning, one_step_agent(), small;
                    worldmodel = lavaworld, absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ = 0.0)
                nothing
            catch caught
                caught
            end
            @test stub_error isa ErrorException && occursin("Oooops!", stub_error.msg)
            # each blank on its own trips the guard -
            for (blank, answer) in (("a = 0;", "a = argmax(Q[s,:]);"),
                                    ("target = NaN;", "target = r + γ*maximum(Q[s′,:]);"),
                                    ("Q[s,a] = NaN;", "Q[s,a] = Q[s,a] + α*(target - Q[s,a]);"))
                one_blank = Module(:L12bOneBlank)
                Base.include_string(one_blank, replace(reference_text, answer => blank))
                caught = try
                    Base.invokelatest(one_blank.L12bQLearning.myqlearning, one_step_agent(), small;
                        worldmodel = lavaworld, absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ = 0.0)
                    nothing
                catch e
                    e
                end
                @test caught isa ErrorException && occursin("Oooops!", caught.msg)
            end
            # wrong solutions fail the check cell: a fixed action, a fixed learning rate, the model's γ -
            for (answer, wrong) in (("a = argmax(Q[s,:]);", "a = 2;"),
                                    ("Q[s,a] = Q[s,a] + α*(target - Q[s,a]);", "Q[s,a] = Q[s,a] + 0.5*(target - Q[s,a]);"),
                                    ("target = r + γ*maximum(Q[s′,:]);", "target = r + environment.γ*maximum(Q[s′,:]);"))
                wrong_module = Module(:L12bWrong)
                Base.include_string(wrong_module, replace(reference_text, answer => wrong))
                @test passes_check(wrong_module.L12bQLearning.myqlearning) == false
            end
        end

        @testset "L12b lab notebook" begin
            notebook = "CHEME-5800-L12b-Lab-QLearningGridWorld-Fall-2026.ipynb"
            @test check_local_links("L12b", notebook; markdown_only = false) ≥ 5
            # Run the actual notebook cells with the reference solution in place of the stub -
            (w, cells) = run_notebook("L12b", notebook, :L12bNotebookValidation; solution = "Compute-solution.jl")
            @test occursin("Include.jl", join(cells[1]["source"]))
            @test all(isempty(cell["outputs"]) for cell in cells) # the lab ships without outputs

            # Task 1: the world of the value iteration lab -
            @test w.world.moves == Dict(1 => (-1, 0), 2 => (1, 0), 3 => (0, -1), 4 => (0, 1))
            @test (w.nstates, w.nactions, w.γ) == (400, 4, 0.95)
            @test w.absorbing_state_set == Set([(1, 2), (2, 2), (2, 3), (4, 5), (19, 20), (4, 3)])
            @test length(w.absorbing_states) == 6
            @test all(sum(w.m.T[s, :, a]) ≈ 1.0 for s in w.𝒮 for a in w.𝒜) && count(!iszero, w.m.T) == 1600
            @test w.m.R[w.world.states[(4, 4)], 3] == 100.0 && w.m.R[w.world.states[(1, 1)], 1] == -50000.0
            # the one-move demonstration: left from (20,20) enters the lava pit at (19,20) -
            @test w.lavaworld(w.m, w.world.states[(20, 20)], 1, w.Xoshiro(1)) == (w.world.states[(19, 20)], -1000.0)

            # Task 3: the learned move is optimal in most squares but not all, and the value of (20,20) lags -
            (number_optimal, number_of_squares) = w.count_optimal_moves(w.Qstar, w.π_q, w.absorbing_states)
            @test (number_optimal, number_of_squares) == (337, 394)
            @test maximum(w.result.Q[w.s_start, :]) < w.solution.U[w.s_start] - 1
            # the printed values of (20,20): learned -2.35, optimal 3.25 -
            @test round(maximum(w.result.Q[w.s_start, :]), digits = 2) == -2.35
            @test round(w.solution.U[w.s_start], digits = 2) == 3.25
            # the check cell's expectations match the ones tested above -
            check_source = join(cells[findfirst(c -> occursin("@testset \"My Q-learning\"", join(c["source"])), cells)]["source"])
            @test occursin("[0.0 2.0; 0.0 0.0; 0.0 0.0]", check_source) && occursin("[4.25 4.0; 0.0 0.0; 0.0 0.0]", check_source)
            # both policies reach the station from (20,20) in 33 moves -
            @test (w.outcome, length(w.path) - 1) == ("reached the charging station", 33)
            @test (w.outcome_star, length(w.path_star) - 1) == ("reached the charging station", 33)

            # the what-if cell and the answers to its questions -
            function train(episodes, ϵ)
                agent = build(MyQLearningAgentModel, (states = w.𝒮, actions = w.𝒜, α = w.α, γ = w.γ, Q = zeros(400, 4)))
                result = L12bQLearning.myqlearning(agent, w.m; worldmodel = w.lavaworld, absorbing = w.absorbing_states,
                    episodes = episodes, maxsteps = w.maxsteps, ϵ = ϵ, seed = 5800)
                π = policy(result.Q)
                (path, outcome) = w.follow_policy(π, w.startstate, w.world, w.rewards, w.absorbing_state_set;
                    charging_reward = w.charging_reward)
                optimal = w.count_optimal_moves(w.Qstar, π, w.absorbing_states)[1]
                positive = count(s -> !(s in w.absorbing_states) && maximum(result.Q[s, :]) > 0, w.𝒮)
                return (outcome = outcome, moves = length(path) - 1, optimal = optimal, steps = sum(result.visits), positive = positive)
            end
            short = train(200, 0.1)
            @test short.outcome == "walks in a loop" && short.optimal == 269
            # the path includes the move that closes the loop: (20,20) to (20,19) and back -
            @test short.moves == 2
            # "the reward has spread only to the squares near the station" -
            @test short.positive < train(2000, 0.1).positive
            # the greedy question: every move costs, so an untried move keeps the larger value zero -
            greedy = train(2000, 0.0)
            @test (greedy.outcome, greedy.moves) == ("reached the charging station", 33)
            # the random-move question: every square optimal, at the price of many more moves -
            random = train(2000, 1.0)
            @test random.optimal == 394 && random.steps > 10 * sum(w.result.visits)
            # "Longer training, or more exploration, spread the reward over more of the grid" -
            @test train(200, 1.0).optimal > short.optimal && number_optimal > short.optimal
        end
    end
end

@meeting "L12c" begin
    @testset "L12c lecture" begin
        @test check_local_links("L12c", "CHEME-5800-L12c-Lecture-ValueIterationVsQLearning-Fall-2026.ipynb") ≥ 2
        # "66 sweeps for γ = 0.9, but 688 sweeps for γ = 0.99" to shrink the error by a factor of 1000 -
        @test ceil(Int, log(1000) / log(1 / 0.9)) == 66
        @test ceil(Int, log(1000) / log(1 / 0.99)) == 688
        # "Two variables on 41 levels give 1681 states, but ten ... about 1.3 × 10^16" -
        @test 41^2 == 1681 && round(41.0^10, sigdigits = 2) == 1.3e16
    end
end

@meeting "L12d" begin
    @testset "L12d bioreactor lab" begin
        notebook = "CHEME-5800-L12d-Lab-ExplorationAndReproducibility-Fall-2026.ipynb"
        @test check_local_links("L12d", notebook; markdown_only = false) ≥ 4
        # the walkthrough's code is complete -
        for file in readdir(joinpath(WEEK_ROOT, "L12d", "src"))
            @test !occursin("TODO", read(joinpath(WEEK_ROOT, "L12d", "src", file), String))
        end
        (w, cells) = run_notebook("L12d", notebook, :L12dNotebookValidation)
        @test all(isempty(cell["outputs"]) for cell in cells) # the lab ships without outputs
        env = w.env

        # Task 1: 9261 states; no fixed feed harvests -
        @test (w.nstates, w.nactions) == (9261, 4)
        fixed = [w.simulate(env, fill(a, w.nstates), w.s₀) for a in 1:4]
        @test [(r.outcome, r.steps) for r in fixed] == [(:timeout, 80), (:timeout, 80), (:crash, 10), (:crash, 7)]
        @test all(r.product == 0.0 for r in fixed)
        @test (length(fixed[1].X), length(fixed[1].feed)) == (81, 81) # a timeout records the state after the last cycle
        # "the low feed adds a third of a level, which rounds back": the volume never moves -
        @test all(V ≈ env.V0 for V in fixed[2].V)
        # a harvest on the last allowed cycle is a harvest, with its product -
        at_limit = w.simulate(env, w.π_star, w.s₀; maxsteps = 13, γ = w.γ)
        @test (at_limit.outcome, at_limit.steps, round(at_limit.product, digits = 2)) == (:harvest, 13, 0.65)
        @test at_limit.G == w.optimal.G && at_limit.X == w.optimal.X
        @test_logs (:warn, r"k_max") w.solve(env; γ = 0.95, k_max = 1)
        # the optimal batch: harvest in 13 cycles, product 0.65, G = 0.351 -
        @test (w.optimal.outcome, w.optimal.steps, round(w.optimal.product, digits = 2), round(w.optimal.G, digits = 3)) ==
              (:harvest, 13, 0.65, 0.351)
        # "medium in most cycles; in the last few cycles it alternates feeding with rest cycles of no feed" -
        feeds = round.(w.optimal.feed[1:13], digits = 2)
        @test count(==(0.67), feeds) ≥ 9 && feeds[10] == 0.0 && feeds[12] == 0.0 && feeds[11] == 0.67 && feeds[13] == 0.67

        # Task 2: seed 5800 and seed 1 at 20,000 episodes, and the same seed twice -
        @test (w.learned.outcome, w.learned.steps, round(w.learned.product, digits = 2), round(w.learned.G, digits = 3)) ==
              (:harvest, 15, 0.6, 0.293)
        @test w.result_again.Q == w.result.Q
        # absorbing rows are set to zero even when the starting table is not zero -
        hundreds = build(MyQLearningAgentModel, (states = collect(1:w.nstates), actions = collect(1:4), α = 0.1, γ = w.γ,
            Q = fill(100.0, w.nstates, 4)))
        from_hundreds = solve(hundreds, env; episodes = 10, maxsteps = 5, seed = 1)
        @test all(from_hundreds.Q[s, :] == zeros(4) for s in 1:w.nstates if w.isterminal(env, s))
        function train_and_run(seed, episodes; ϵ_start = 1.0, ϵ_floor = 0.05)
            result = solve(w.agent, env; episodes = episodes, seed = seed, ϵ_start = ϵ_start, ϵ_floor = ϵ_floor)
            batch = w.simulate(env, policy(result.Q), w.s₀; γ = w.γ)
            return (outcome = batch.outcome, steps = batch.steps, product = round(batch.product, digits = 2),
                G = round(batch.G, digits = 3), untried = w.count_untried_pairs(env, result.visits)[1])
        end
        seed_one = train_and_run(1, 20_000)
        @test (seed_one.outcome, seed_one.steps, seed_one.product, seed_one.G) == (:harvest, 13, 0.55, 0.297)
        @test seed_one.G < w.optimal.G && w.learned.G < w.optimal.G
        # the question: at 200,000 episodes the seeds agree on the product, within a cycle of the optimum -
        long_runs = [train_and_run(seed, 200_000) for seed in (5800, 1, 2)]
        @test [(r.steps, r.product, r.G) for r in long_runs] == [(14, 0.65, 0.334), (13, 0.65, 0.351), (13, 0.65, 0.351)]

        # Task 3: the greedy agent only ever chose "no feed" and never harvests -
        @test w.greedy_batch.outcome == :timeout
        @test sum(w.greedy.visits, dims = 1) == [16_000_000 0 0 0]
        @test w.count_untried_pairs(env, w.greedy.visits) == (22680, 30240)
        # the exploring agent (the what-if cell's defaults) harvests the optimal product -
        exploring = train_and_run(5800, 200_000)
        @test (exploring.outcome, exploring.product, exploring.untried) == (:harvest, 0.65, 546)
        # the question: 2,000 episodes time out; a fixed ϵ = 0.1 harvests but leaves more pairs untried -
        few = train_and_run(5800, 2_000)
        @test (few.outcome, few.untried) == (:timeout, 20021)
        fixed_ϵ = train_and_run(5800, 200_000; ϵ_start = 0.1, ϵ_floor = 0.1)
        @test (fixed_ϵ.outcome, fixed_ϵ.steps, fixed_ϵ.product, fixed_ϵ.untried) == (:harvest, 13, 0.65, 4181)
    end
end
