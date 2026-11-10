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

# The myqlearning(...) of a module that include_string defined after this file was compiled.
# Reading the binding through invokelatest avoids Julia 1.12's world-age warning.
function latest_myqlearning(mod::Module)
    inner = Base.invokelatest(getglobal, mod, :L12bQLearning)
    return Base.invokelatest(getglobal, inner, :myqlearning)
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
    @test length(listed) == 9
    for file in listed
        @test isfile(joinpath(WEEK_ROOT, file))
        endswith(file, ".ipynb") && @test occursin(file, readme)
    end
end

@meeting "L12a" begin
    @testset "L12a lecture and example" begin
        @test check_local_links("L12a", "CHEME-5800-L12a-Lecture-QLearning-Fall-2026.ipynb") ≥ 4

        # a three-state problem whose action values we know by hand -
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

        @testset "Package Q-learning" begin
            one_step = solve(one_step_agent(), small; worldmodel = lavaworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ = 0.0)
            @test one_step.visits == [0 1; 0 0; 0 0]
            @test one_step.Q ≈ [0.0 2.0; 0.0 0.0; 0.0 0.0]
            other_step = solve(other_agent(), small; worldmodel = lavaworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ = 0.0)
            @test other_step.visits == [1 0; 0 0; 0 0]
            @test other_step.Q ≈ [4.25 4.0; 0.0 0.0; 0.0 0.0]
            # absorbing rows are set to zero even when the starting table is not zero -
            hundreds = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 1.0, γ = 0.9, Q = fill(100.0, 3, 2)))
            from_hundreds = solve(hundreds, small; worldmodel = lavaworld,
                absorbing = Set([3]), episodes = 500, maxsteps = 50, ϵ = 1.0)
            @test from_hundreds.Q ≈ [8.0 5.2; 10.0 6.2; 0.0 0.0]
            agent = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 1.0, γ = 0.9, Q = zeros(3, 2)))
            exact = solve(agent, small; worldmodel = lavaworld,
                absorbing = Set([3]), episodes = 500, maxsteps = 50, ϵ = 1.0)
            @test exact.Q ≈ [8.0 5.2; 10.0 6.2; 0.0 0.0]
            @test agent.Q == zeros(3, 2) # the agent's own table is not changed
            # the same seed gives the same table -
            again = solve(agent, small; worldmodel = lavaworld,
                absorbing = Set([3]), episodes = 500, maxsteps = 50, ϵ = 1.0)
            @test again.Q == exact.Q && again.visits == exact.visits
            # the example's code is complete -
            for file in readdir(joinpath(WEEK_ROOT, "L12a", "src"))
                @test !occursin("TODO", read(joinpath(WEEK_ROOT, "L12a", "src", file), String))
            end
        end

        @testset "L12a example notebook" begin
            example = "CHEME-5800-L12a-Example-QLearningGridWorld-Fall-2026.ipynb"
            @test check_local_links("L12a", example; markdown_only = false) ≥ 5

            # The example ships with outputs, none of them errors -
            shipped = [cell for cell in JSON.parsefile(joinpath(WEEK_ROOT, "L12a", example))["cells"] if cell["cell_type"] == "code"]
            @test count(cell -> !isempty(cell["outputs"]), shipped) ≥ 5
            @test all(output["output_type"] != "error" for cell in shipped for output in cell["outputs"])

            # Run the example's cells -
            (w, cells) = run_notebook("L12a", example, :L12aExampleValidation)
            @test occursin("Include.jl", join(cells[1]["source"]))

            # Task 1: the world of the value iteration lab -
            @test w.world.moves == Dict(1 => (-1, 0), 2 => (1, 0), 3 => (0, -1), 4 => (0, 1))
            @test (w.nstates, w.nactions, w.γ) == (400, 4, 0.95)
            @test w.absorbing_state_set == Set([(1, 2), (2, 2), (2, 3), (4, 5), (19, 20), (4, 3)])
            @test length(w.absorbing_states) == 6
            @test all(sum(w.m.T[s, :, a]) ≈ 1.0 for s in w.𝒮 for a in w.𝒜) && count(!iszero, w.m.T) == 1600
            @test w.m.R[w.world.states[(4, 4)], 3] == 100.0 && w.m.R[w.world.states[(1, 1)], 1] == -50000.0
            # the one-move demonstration: left from (20,20) enters the lava pit at (19,20) -
            @test w.lavaworld(w.m, w.world.states[(20, 20)], 1, w.Xoshiro(1)) == (w.world.states[(19, 20)], -1000.0)

            # Task 2: the absorbing rows of the grid world run are never visited or updated -
            @test all(w.result.Q[s, :] == zeros(4) && w.result.visits[s, :] == zeros(Int64, 4) for s in w.absorbing_states)

            # Task 3: both policies reach the station from (20,20) in 33 moves, by different routes -
            @test (w.outcome, length(w.path) - 1) == ("reached the charging station", 33)
            @test (w.outcome_star, length(w.path_star) - 1) == ("reached the charging station", 33)
            @test w.path != w.path_star
            # the Task 3 figure draws the two paths -
            @test count(c -> occursin("draw_paths(", join(c["source"])) && occursin("path_star", join(c["source"])), cells) == 1
            # the scores cell: both policies earn the optimal value of (20,20), 3.25, and the learned
            # estimate is -2.35. Recompute the scores here rather than trusting the saved printout -
            s0 = w.world.states[(20, 20)]
            function score_of(π)
                total = 0.0
                s = s0
                for t in 1:w.maxsteps
                    s in w.absorbing_states && break
                    (s′, r) = w.lavaworld(w.m, s, π[s], w.Xoshiro(1))
                    total += w.γ^(t - 1) * r
                    s = s′
                end
                return total
            end
            @test score_of(w.π_q) ≈ score_of(w.π_star) ≈ w.solution.U[s0]
            @test round(score_of(w.π_q), digits = 2) == 3.25
            @test round(maximum(w.result.Q[s0, :]), digits = 2) == -2.35
            score_cell = cells[findfirst(c -> occursin("println(\"score of the learned policy", join(c["source"])), cells)]
            score_text = join([join(o["text"]) for o in score_cell["outputs"] if o["output_type"] == "stream"])
            @test occursin("score of the learned policy from (20, 20): 3.25 (the learned estimate: -2.35)", score_text)
            @test occursin("score of the optimal policy from (20, 20): 3.25", score_text)
            # "Along the whole path, the move with the highest estimate is also a best move" -
            for k in 1:(length(w.path) - 1)
                s = w.world.states[w.path[k]]
                @test w.Qstar[s, w.π_q[s]] ≥ maximum(w.Qstar[s, :]) - 1e-6
            end
            # "the reward has not fully reached the far corner": the estimate is below the optimal value -
            @test maximum(w.result.Q[s0, :]) < w.solution.U[s0]
            # Key Takeaway 3: "more than 50,000 moves of trial and error" -
            @test sum(w.result.visits) > 50000
        end
    end
end

@meeting "L12b" begin
    @testset "L12b adaptive dosing lab" begin
        # a three-state problem with answers worked out by hand -
        T_small = zeros(3, 3, 2)
        R_small = zeros(3, 2)
        T_small[1, 2, 1] = 1.0; R_small[1, 1] = -1.0
        T_small[1, 1, 2] = 1.0; R_small[1, 2] = -2.0
        T_small[2, 3, 1] = 1.0; R_small[2, 1] = 10.0
        T_small[2, 1, 2] = 1.0; R_small[2, 2] = -1.0
        T_small[3, 3, 1] = 1.0; T_small[3, 3, 2] = 1.0
        small = build(MyMDPProblemModel, (𝒮 = [1, 2, 3], 𝒜 = [1, 2], T = T_small, R = R_small, γ = 0.9))
        greedy_agent() = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2],
            α = 0.1, γ = 0.5, Q = [6.0 4.0; 0.0 0.0; 0.0 0.0]))
        average_agent() = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2],
            α = 0.1, γ = 0.5, Q = [0.0 10.0; 0.0 0.0; 0.0 0.0]))
        # the expected tables of that problem; true when a myqlearning(...) passes both -
        function passes_check(f)
            greedy_step = Base.invokelatest(f, greedy_agent(), small; worldmodel = L12bUtility.mdpworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ_start = 0.0, ϵ_floor = 0.0)
            two_steps = Base.invokelatest(f, average_agent(), small; worldmodel = L12bUtility.mdpworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 2, ϵ_start = 0.0, ϵ_floor = 0.0)
            return greedy_step.visits == [1 0; 0 0; 0 0] && greedy_step.Q ≈ [-1.0 4.0; 0.0 0.0; 0.0 0.0] &&
                   two_steps.visits == [0 2; 0 0; 0 0] && two_steps.Q ≈ [0.0 1.25; 0.0 0.0; 0.0 0.0]
        end

        @testset "Reference Q-learning" begin
            @test passes_check(L12bQLearning.myqlearning)
            # mdpworld follows the certain moves of the small problem -
            @test L12bUtility.mdpworld(small, 1, 2) == (1, -2.0) && L12bUtility.mdpworld(small, 2, 1) == (3, 10.0)
            # the agent's own table is not changed -
            agent = greedy_agent()
            L12bQLearning.myqlearning(agent, small; worldmodel = L12bUtility.mdpworld,
                absorbing = Set([2, 3]), episodes = 1, maxsteps = 1, ϵ_start = 0.0, ϵ_floor = 0.0)
            @test agent.Q == [6.0 4.0; 0.0 0.0; 0.0 0.0]
            # absorbing rows are set to zero even when the starting table is not zero -
            hundreds = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 0.1, γ = 0.9, Q = fill(100.0, 3, 2)))
            from_hundreds = L12bQLearning.myqlearning(hundreds, small; worldmodel = L12bUtility.mdpworld,
                absorbing = Set([3]), episodes = 50, maxsteps = 10)
            @test from_hundreds.Q[3, :] == [0.0, 0.0] && from_hundreds.visits[3, :] == [0, 0]
            # with 1/n and full exploration, the values approach the optimal ones -
            explorer = build(MyQLearningAgentModel, (states = [1, 2, 3], actions = [1, 2], α = 0.1, γ = 0.9, Q = zeros(3, 2)))
            long_run = L12bQLearning.myqlearning(explorer, small; worldmodel = L12bUtility.mdpworld,
                absorbing = Set([3]), episodes = 20_000, maxsteps = 50, ϵ_start = 1.0, ϵ_floor = 1.0)
            @test isapprox(long_run.Q, [8.0 5.2; 10.0 6.2; 0.0 0.0]; atol = 0.05)
            # the same seed gives the same table -
            again = L12bQLearning.myqlearning(explorer, small; worldmodel = L12bUtility.mdpworld,
                absorbing = Set([3]), episodes = 20_000, maxsteps = 50, ϵ_start = 1.0, ϵ_floor = 1.0)
            @test again.Q == long_run.Q && again.visits == long_run.visits
            # the package's Q-learning, with 1/n and the same falling ϵ, gives the same table -
            schedule(i) = max(0.05, 1.0 - i/(0.7*400))
            reference = L12bQLearning.myqlearning(explorer, small; worldmodel = L12bUtility.mdpworld,
                absorbing = Set([3]), episodes = 400, maxsteps = 20, seed = 1234)
            package = solve(explorer, small; worldmodel = (p, s, a, rng) -> L12bUtility.mdpworld(p, s, a),
                absorbing = Set([3]), episodes = 400, maxsteps = 20, ϵ = schedule, learningrate = :visits, seed = 1234)
            @test package.Q == reference.Q && package.visits == reference.visits
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
            @test Set(names(Base.invokelatest(getglobal, student_module, :L12bQLearning))) == Set([:L12bQLearning, :myqlearning])
            stub_error = try
                Base.invokelatest(latest_myqlearning(student_module), greedy_agent(), small;
                    worldmodel = L12bUtility.mdpworld, absorbing = Set([2, 3]), episodes = 1, maxsteps = 1,
                    ϵ_start = 0.0, ϵ_floor = 0.0)
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
                    Base.invokelatest(latest_myqlearning(one_blank), greedy_agent(), small;
                        worldmodel = L12bUtility.mdpworld, absorbing = Set([2, 3]), episodes = 1, maxsteps = 1,
                        ϵ_start = 0.0, ϵ_floor = 0.0)
                    nothing
                catch e
                    e
                end
                @test caught isa ErrorException && occursin("Oooops!", caught.msg)
            end
            # wrong solutions fail these expectations: a fixed or the worst action, the wrong row or the
            # model's γ in the target, a fixed learning rate, and no averaging at all -
            for (answer, wrong) in (("a = argmax(Q[s,:]);", "a = 2;"),
                                    ("a = argmax(Q[s,:]);", "a = argmin(Q[s,:]);"),
                                    ("target = r + γ*maximum(Q[s′,:]);", "target = r + γ*maximum(Q[s,:]);"),
                                    ("target = r + γ*maximum(Q[s′,:]);", "target = r + environment.γ*maximum(Q[s′,:]);"),
                                    ("Q[s,a] = Q[s,a] + α*(target - Q[s,a]);", "Q[s,a] = Q[s,a] + 0.5*(target - Q[s,a]);"),
                                    ("Q[s,a] = Q[s,a] + α*(target - Q[s,a]);", "Q[s,a] = target;"))
                wrong_module = Module(:L12bWrong)
                Base.include_string(wrong_module, replace(reference_text, answer => wrong))
                @test passes_check(latest_myqlearning(wrong_module)) == false
            end
        end

        @testset "L12b lab notebook" begin
            notebook = "CHEME-5800-L12b-Lab-AdaptiveDosing-QLearning-Fall-2026.ipynb"
            @test check_local_links("L12b", notebook; markdown_only = false) ≥ 6
            # Run the actual notebook cells with the reference solution in place of the stub -
            (w, cells) = run_notebook("L12b", notebook, :L12bNotebookValidation; solution = "Compute-solution.jl")
            @test occursin("Include.jl", join(cells[1]["source"]))
            @test all(isempty(cell["outputs"]) for cell in cells) # the lab ships without outputs
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
            # after the last dose: the equations of Task 1 with no dose, for 40 more cycles -
            @test length(w.B_after) == length(w.Z_after) == 41 && w.B_after[1] == w.optimal.B[end] && w.Z_after[1] == w.optimal.Z[end]
            @test all(w.Z_after[2:end] .< w.Z_after[1:end-1]) && all(w.B_after[2:end] .> w.B_after[1:end-1])
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

            # Task 3: the absorbing states are the cures and the toxic deaths -
            @test w.absorbing_states == Set(s for s in 1:w.nstates if w.isterminal(env, s)) && length(w.absorbing_states) == 385
            # the learned policy gives the same doses from the start -
            @test w.learned.outcome == :cured && w.learned.dose == w.optimal.dose
            @test all(w.result.Q[s, :] == zeros(4) for s in w.absorbing_states) # absorbing rows stay zero
            @test all(w.result.visits[s, :] == zeros(Int64, 4) for s in w.absorbing_states)
            # absorbing rows are set to zero even when the starting table is not zero -
            hundreds = build(MyQLearningAgentModel, (states = collect(1:w.nstates), actions = collect(1:4), α = 0.1, γ = 0.95,
                Q = fill(100.0, w.nstates, 4)))
            from_hundreds = L12bQLearning.myqlearning(hundreds, env; worldmodel = w.world, absorbing = w.absorbing_states,
                episodes = 10, maxsteps = 5, seed = 1)
            @test all(from_hundreds.Q[s, :] == zeros(4) for s in w.absorbing_states)
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
            # "These states are visited less often during training, and they have two doses of similar value" -
            middle(v) = sort(v)[cld(length(v), 2)]
            differ = [s for s in visited if w.π_q[s] != w.π_star[s]]
            agree = [s for s in visited if w.π_q[s] == w.π_star[s]]
            @test middle([sum(w.result.visits[s, :]) for s in differ]) < middle([sum(w.result.visits[s, :]) for s in agree]) / 2
            best_gap(s) = sort(w.Qstar[s, :], rev = true)[1] - sort(w.Qstar[s, :], rev = true)[2]
            @test middle(best_gap.(differ)) < 0.1 && middle(best_gap.(agree)) > 1.0
            # Four starts: both cure, and the learned policy takes at most one more cycle -
            rows = [(w.simulate(env, w.π_star, w.stateindex(env, B₀, 0.0)), w.simulate(env, w.π_q, w.stateindex(env, B₀, 0.0)))
                    for B₀ in (0.30, 0.50, 0.70, 0.90)]
            @test [(a.steps, b.steps) for (a, b) in rows] == [(6, 7), (9, 9), (12, 13), (13, 13)]
            @test all(a.outcome == :cured && b.outcome == :cured for (a, b) in rows)
        end
    end
end

@meeting "L12c" begin
    @testset "L12c lecture" begin
        lecture = "CHEME-5800-L12c-Lecture-DeepQLearning-Fall-2026.ipynb"
        @test check_local_links("L12c", lecture) ≥ 3 # the example, the figure, and the lab
        # "Two variables on 41 levels give 1681 states ... ten variables ... about 1.3 × 10^16" -
        @test 41^2 == 1681 && round(41.0^10, sigdigits = 2) == 1.3e16
        # "148 weights, where the L12b Q-table has 6,724 entries" -
        @test 4 * (6^2 + 1) == 148 && 4 * 41^2 == 6724
        # "A check against the table": with one-hot features, one transition, and θ⁻ = θ, the
        # linear gradient step is the Q-learning update -
        W = [1.0 2.0 3.0; 4.0 5.0 6.0] # 2 actions × 3 states: the Q-table, transposed
        (s, a, r, s′, α, γ) = (1, 2, 0.5, 3, 0.25, 0.9)
        φ = [1.0, 0.0, 0.0]; φ′ = [0.0, 0.0, 1.0]
        y = r + γ * maximum(W * φ′)
        W_step = copy(W); W_step[a, :] .+= α * (y - sum(W[a, :] .* φ)) .* φ
        Q = permutedims(W); Q[s, a] += α * (r + γ * maximum(Q[s′, :]) - Q[s, a])
        @test W_step ≈ permutedims(Q)
    end

    @testset "L12c example" begin
        example = "CHEME-5800-L12c-Example-LinearDQN-AdaptiveDosing-Fall-2026.ipynb"
        @test check_local_links("L12c", example; markdown_only = false) ≥ 6

        # The example ships with outputs, none of them errors -
        shipped = [cell for cell in JSON.parsefile(joinpath(WEEK_ROOT, "L12c", example))["cells"] if cell["cell_type"] == "code"]
        @test count(cell -> !isempty(cell["outputs"]), shipped) ≥ 9
        @test all(output["output_type"] != "error" for cell in shipped for output in cell["outputs"])

        (w, cells) = run_notebook("L12c", example, :L12cExampleValidation)
        patient = w.patient

        # Task 1: one full dose from (0.90, 0) gives (0.5985, 0.5), "rounded to (0.600, 0.500)" on the lab grid -
        (B′, Z′, r, done) = w.treat(patient, 0.90, 0.0, 4)
        @test (round(B′, digits = 4), Z′, round(r, digits = 4), done) == (0.5985, 0.5, -1.1985, false)
        @test round(B′ / 0.025) * 0.025 ≈ 0.6
        # a start where the treatment has already ended is absorbing: no change, no reward, no dose -
        @test w.treat(patient, 0.05, 0.95, 4) == (0.05, 0.95, 0.0, true)
        @test w.treat(patient, 0.10, 0.0, 1) == (0.10, 0.0, 0.0, true)
        dead = w.simulate(patient, w.trained; B₀ = 0.05, Z₀ = 0.95, γ = 0.95)
        @test (dead.outcome, dead.cycles, dead.G, length(dead.dose)) == (:dead, 0, 0.0, 0)
        cured = w.simulate(patient, w.grid_41; B₀ = 0.10, Z₀ = 0.0, γ = 0.95)
        @test (cured.outcome, cured.cycles, cured.G, length(cured.dose)) == (:cured, 0, 0.0, 0)

        # Task 2: 37 features, 148 weights; the two nearest centers are 0.10 away, bumps ≈ 0.80 -
        @test (length(w.φ), length(w.network.W)) == (37, 148)
        @test round(maximum(w.φ[1:end-1]), digits = 2) == 0.80
        @test count(x -> x ≈ maximum(w.φ[1:end-1]), w.φ[1:end-1]) == 2
        @test w.network.centers[31, :] == [1.0, 0.0] && w.network.centers[25, :] == [0.8, 0.0]
        @test (w.result.cycles, w.result.updates) == (43609, 42610)
        # "cures the patient in 23 cycles ... the full dose only twice and never two cycles in a row" -
        @test (w.run_dqn.outcome, w.run_dqn.cycles, round(w.run_dqn.G, digits = 2)) == (:cured, 23, 5.12)
        full = findall(==(1.0), w.run_dqn.dose)
        @test length(full) == 2 && all(diff(full) .> 1)
        @test all(Z < patient.Zlethal for Z in w.run_dqn.Z)

        # Task 3: the 41-level policy is the lab's optimal policy -
        if released("L12b")
            env = build(MyAdaptiveDosingModel, (nlevels = 41, doses = [0.0, 1/3, 2/3, 1.0], g = 0.15, k = 0.35,
                b = 0.50, c = 0.35, Bcure = 0.10, Zlethal = 0.90, wB = 1.0, wZ = 1.0, wu = 0.10, rcure = 60.0, rdead = -60.0))
            Qlab = solve(env; γ = 0.95)
            @test all(argmax(Qlab[s, :]) == w.grid_41.π[env.coordinates[s]...] for s in 1:41^2 if !L12bUtility.isterminal(env, s))
        end
        # "201-level policy cures in 19 cycles, the linear DQN takes 23, the 41-level policy never cures" -
        @test (w.run_201.outcome, w.run_201.cycles, round(w.run_201.G, digits = 2)) == (:cured, 19, 10.96)
        @test (w.run_41.outcome, w.run_41.cycles, round(w.run_41.G, digits = 2)) == (:timeout, 100, -18.21)
        # "then the tumor stays between 0.10 and 0.13"; the state (0.109, 0.816) is reached at the start of cycle 21, after 20 treatments (B[1] is the start) -
        @test all(0.10 < B < 0.13 for B in w.run_41.B[20:end])
        @test (round(w.run_41.B[21], digits = 3), round(w.run_41.Z[21], digits = 3)) == (0.109, 0.816)
        @test w.patient.doses[w.gridaction(w.grid_41, 0.109, 0.816)] == 0.0
        @test round(0.109 / 0.025) * 0.025 ≈ 0.100
        # the eight starts: the DQN cures from all, with 0 to 4 more cycles than the 201-level grid -
        @test all(w.comparison.dqn_outcome .== :cured) && all(w.comparison.grid_outcome .== :cured)
        @test w.comparison.dqn_cycles == [12, 13, 20, 21, 20, 22, 23, 24]
        @test w.comparison.grid_cycles == [10, 13, 16, 17, 19, 19, 19, 20]
        @test extrema(w.comparison.dqn_cycles .- w.comparison.grid_cycles) == (0, 4)
        # "161604 entries, about a thousand times the 148 weights" -
        @test 201^2 * 4 == 161604 && round(161604 / 148, sigdigits = 1) == 1000
    end
end

@meeting "L12d" begin
    @testset "L12d Double DQN lab" begin
        notebook = "CHEME-5800-L12d-Lab-DoubleDQN-Fall-2026.ipynb"
        @test check_local_links("L12d", notebook; markdown_only = false) ≥ 4
        # the walkthrough's code is complete -
        for file in readdir(joinpath(WEEK_ROOT, "L12d", "src"))
            @test !occursin("TODO", read(joinpath(WEEK_ROOT, "L12d", "src", file), String))
        end
        (w, cells) = run_notebook("L12d", notebook, :L12dNotebookValidation)
        @test all(isempty(cell["outputs"]) for cell in cells) # the lab ships without outputs
        pct(x) = round(Int, 100 * x)

        # Task 1: "about 0.39", "-0.10"; 100 actions: "about 0.69" -
        @test round(w.estimates.single, digits = 2) == 0.39 && round(w.estimates.double, digits = 2) == -0.10
        hundred = maxbias(nactions = 100, nsamples = 10, μ = -0.1, trials = 10_000, seed = 1234)
        @test round(hundred.single, digits = 2) == 0.69 && round(hundred.double, digits = 2) == -0.10
        # the question: one action shows no bias; 100 rewards per action leave a small one -
        one = maxbias(nactions = 1, nsamples = 10, μ = -0.1, trials = 10_000, seed = 1234)
        many = maxbias(nactions = 10, nsamples = 100, μ = -0.1, trials = 10_000, seed = 1234)
        @test abs(one.single + 0.1) < 0.01 && round(many.single, digits = 2) == 0.05

        # Task 2: Q-learning peaks at 94% in episode 20 and ends near 12%; Double Q stays ≤ 51% and is below 10% by episode 82 -
        @test (pct(maximum(w.left_q)), argmax(w.left_q), pct(w.left_q[300])) == (94, 20, 12)
        @test pct(maximum(w.left_double)) == 51 && findfirst(<(0.1), w.left_double) == 82
        @test w.left_q == twostate_qlearning(double = false, seed = 1234) # the defaults are the cell's settings
        hundred_B = (twostate_qlearning(nB = 100, seed = 1234), twostate_qlearning(double = true, nB = 100, seed = 1234))
        @test (pct(hundred_B[1][300]), pct(hundred_B[2][300])) == (95, 7)
        # the question: with one action in B, Q-learning never rises above the first episodes' coin flip -
        one_B = twostate_qlearning(nB = 1, seed = 1234)
        @test pct(maximum(one_B)) == 51 && argmax(one_B) ≤ 3

        # Task 3: DQN peaks at 94% and Double DQN at 86%; at episode 300, 69% and 54% -
        @test (pct(maximum(w.left_dqn)), pct(maximum(w.left_ddqn))) == (94, 86)
        @test (pct(w.left_dqn[300]), pct(w.left_ddqn[300])) == (69, 54)
        # C = 1: the two curves are the same -
        @test twostate_dqn(double = false, C = 1, seed = 1234) == twostate_dqn(double = true, C = 1, seed = 1234)
        # the question: C = 100 widens the gap, and the first 60 episodes stay near 50% -
        slow = (twostate_dqn(double = false, C = 100, seed = 1234), twostate_dqn(double = true, C = 100, seed = 1234))
        @test (pct(slow[1][300]), pct(slow[2][300])) == (68, 44)
        @test all(0.4 < x < 0.6 for x in slow[1][1:60])
    end
end
