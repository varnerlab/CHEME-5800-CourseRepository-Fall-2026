# L5d is walked through in class, so this file ships the complete implementation.
# It matches src/Compute-solution.jl apart from this header. After class, try
# rewriting build_teaching_network(...) from its docstring and compare.
module L5dMinCostFlow

import CSV # read the department's input tables
import DataFrames: DataFrame, allowmissing!, nrow # store and inspect labeled tables
import GLPK # solve the minimum-cost flow linear program
import JuMP # describe decision variables, constraints, and the objective
import LinearAlgebra: dot # independently recompute the objective from costs and flows
import MathOptInterface as MOI # compare the solver's status with OPTIMAL

export FlowEdge, flow_formulation, solve_flow_lp, solve_min_cost_flow, validate_flow_solution,
    read_department, staffing_totals, build_teaching_network, teaching_schedule,
    schedule_checks, assignments_by_faculty, with_load, with_preference, with_fixed,
    with_cost, with_staffing

"""
    FlowEdge(source, target, cost, lower, upper)

Store a directed edge and its linear-program data. `source` and `target` are
distinct integer node identifiers. `cost` is the cost per unit of flow, while
`lower` and `upper` are the required minimum and allowed maximum flows.

For the teaching network, flow is measured in assignments and cost in survey-score
points per assignment. All three edge values must be finite, with
`0 <= lower <= upper`; a negative cost is allowed for an assignment bonus.
"""
struct FlowEdge
    source::Int64 # node from which flow leaves; the -1 entry in its incidence column
    target::Int64 # node that receives flow; the +1 entry in its incidence column
    cost::Float64 # w_j: score points per assignment in the teaching model
    lower::Float64 # ℓ_j: minimum flow on this edge
    upper::Float64 # c_j: maximum flow on this edge

    function FlowEdge(source::Integer, target::Integer, cost::Real, lower::Real, upper::Real)
        # Check the edge data -
        # Bool is an Integer in Julia, but true and false are not node identifiers here.
        source isa Bool && throw(ArgumentError("source must be a vertex identifier"))
        target isa Bool && throw(ArgumentError("target must be a vertex identifier"))
        source == target && throw(ArgumentError("self edges are not supported"))
        all(isfinite, (cost, lower, upper)) || throw(ArgumentError("edge values must be finite"))
        0 <= lower <= upper || throw(ArgumentError("edge bounds must satisfy 0 ≤ lower ≤ upper"))
        # Store consistent numeric types for network assembly and the solver -
        return new(Int64(source), Int64(target), Float64(cost), Float64(lower), Float64(upper))
    end
end

# --- Department data ---------------------------------------------------------

"""
    read_department(folder::AbstractString)

Read the four department tables from `folder` and check that they agree.

# Files
- `Faculty.csv`: columns `name` and `load`. The load is the exact number of
  courses the faculty member teaches this semester.
- `Courses.csv`: columns `course`, `min_faculty`, `max_faculty`, and `title`.
  The staffing bounds count faculty assigned to the course.
- `Preferences.csv`: a `name` column followed by one column per course code.
  Each entry is a survey score from 0 (prepared to teach) to 3 (needs
  significant support), or blank when the pairing is not an option.
- `Assignments.csv`: columns `name` and `course`, one row per fixed assignment.

# Returns
A named tuple with `faculty`, `courses`, `preferences`, `fixed`, and `costs`.
The first three are `DataFrame`s in file order; `preferences` stores blanks as
`missing`. `fixed` is a vector of `(name, course)` pairs. `costs` starts empty;
`with_cost(...)` fills it with costs that replace survey scores.

# Checks
Names and course codes must be unique and must agree across the files. Loads
and staffing bounds must be nonnegative integers with `min_faculty <=
max_faculty`. Scores must be 0, 1, 2, 3, or blank. A fixed assignment must
name a pairing that has a score. An `ArgumentError` reports the first problem.
"""
function read_department(folder::AbstractString)
    # Load the four tables -
    isdir(folder) || throw(ArgumentError("department folder does not exist: $(folder)"))
    read_table(name) = CSV.read(joinpath(folder, name), DataFrame; stripwhitespace = true)
    faculty = read_table("Faculty.csv")
    courses = read_table("Courses.csv")
    preferences = read_table("Preferences.csv")
    assignments = read_table("Assignments.csv")
    # Normalize identifiers so table lookups and dictionary keys use the same strings -
    faculty.name = String.(faculty.name)
    courses.course = String.(courses.course)
    courses.title = String.(courses.title)
    preferences.name = String.(preferences.name)
    allowmissing!(preferences, names(preferences)[2:end]) # a follow-up survey may blank any score

    # Collect the model inputs -
    # Tuple keys identify a faculty-course pairing in both the fixed list and cost overrides.
    fixed = [(String(row.name), String(row.course)) for row in eachrow(assignments)]
    department = (faculty = faculty, courses = courses, preferences = preferences, fixed = fixed,
        costs = Dict{Tuple{String,String},Float64}())
    _check_department(department) # reject inconsistent tables before constructing any edges
    return department
end

# Validate the department's data, including changes made by the scenario helpers.
# These checks establish valid inputs; the solver decides whether a schedule exists.
function _check_department(department)
    (; faculty, courses, preferences, fixed) = department
    # Check identifiers and assignment counts -
    allunique(faculty.name) || throw(ArgumentError("faculty names must be unique"))
    allunique(courses.course) || throw(ArgumentError("course codes must be unique"))
    all(load -> load isa Integer && load >= 0, faculty.load) ||
        throw(ArgumentError("every load must be a nonnegative integer"))
    for row in eachrow(courses)
        row.min_faculty isa Integer && row.max_faculty isa Integer ||
            throw(ArgumentError("staffing bounds for $(row.course) must be integers"))
        0 <= row.min_faculty <= row.max_faculty ||
            throw(ArgumentError("staffing bounds for $(row.course) must satisfy 0 ≤ min ≤ max"))
    end
    # Check survey alignment -
    # File order is also the order used to number faculty and course nodes.
    preferences.name == faculty.name ||
        throw(ArgumentError("preference rows must list the faculty in the same order as Faculty.csv"))
    names(preferences)[2:end] == courses.course ||
        throw(ArgumentError("preference columns must list the courses in the same order as Courses.csv"))
    for course in courses.course, score in preferences[!, course]
        ismissing(score) || score in 0:3 ||
            throw(ArgumentError("scores for $(course) must be 0, 1, 2, 3, or blank"))
    end
    # Check department mandates -
    # A fixed assignment must already be an available faculty-course option.
    allunique(fixed) || throw(ArgumentError("fixed assignments must not repeat"))
    for (name, course) in fixed
        name in faculty.name || throw(ArgumentError("fixed assignment names unknown faculty $(name)"))
        course in courses.course || throw(ArgumentError("fixed assignment names unknown course $(course)"))
        ismissing(_score(department, name, course)) &&
            throw(ArgumentError("fixed assignment $(name) → $(course) has no survey score"))
    end
    # Check cost overrides -
    # An override changes the objective coefficient; it cannot create a missing edge.
    for ((name, course), cost) in _costs(department)
        name in faculty.name && course in courses.course && !ismissing(_score(department, name, course)) ||
            throw(ArgumentError("a cost can be set only for an option; $(name) → $(course) is not one"))
        isfinite(cost) || throw(ArgumentError("the cost for $(name) → $(course) must be finite"))
    end
    return nothing # successful validation has no data to return
end

# Costs that replace survey scores; empty unless with_cost(...) was used.
_costs(department) = haskey(department, :costs) ? department.costs : Dict{Tuple{String,String},Float64}()

# Read one survey entry: the faculty name selects a row and the course code a column.
# Callers validate names first; a missing result means this pairing has no edge.
_score(department, name, course) =
    department.preferences[findfirst(==(name), department.preferences.name), course]

"""
    staffing_totals(department)

Compare the total teaching load with the total staffing the courses require
and allow. This is the check we make before solving.

Returns a named tuple with `total_load`, `total_min`, `total_max`, and
`totals_ok`. Every assignment uses one unit of some faculty member's load and
one staffing position in some course, so a schedule can exist only when
`total_min <= total_load <= total_max`. Passing this check does not guarantee
a schedule: it ignores which faculty can teach which courses.
"""
function staffing_totals(department)
    # Compare assignment supply with the aggregate staffing interval -
    total_load = sum(department.faculty.load) # F: assignments the faculty must teach
    total_min = sum(department.courses.min_faculty) # assignments required across all courses
    total_max = sum(department.courses.max_faculty) # assignments allowed across all courses
    return (total_load = total_load, total_min = total_min, total_max = total_max,
        totals_ok = total_min <= total_load <= total_max)
end

"""
    build_teaching_network(department)

Translate the department rules into a flow network with lower and upper bounds.

Node `1` is the source, the faculty follow in file order, then the courses in
file order, then one completion node per course in the same order, and the last
node is the sink. As in the L5a and L5b networks, each course's completion node
passes its flow on to the sink. The edges encode the rules:

| Rule | Edge | Lower bound ℓ | Capacity c | Cost w |
|---|---|---|---|---|
| Exact teaching load | source → faculty | load | load | 0 |
| Survey score 0–3 | faculty → course | 0 | 1 | score, or a `with_cost` value |
| Blank score | no edge | | | |
| Fixed assignment | faculty → course | 1 | 1 | score |
| Course staffing | course → completion | min | max | 0 |
| Course completion | completion → sink | 0 | max | 0 |

One unit of flow is one faculty–course assignment, and cost is measured in
survey-score points. Conservation at a completion node makes its two edges
carry the same flow, so the staffing bounds on the first edge also limit the
second.

# Returns
A named tuple with `edges` (a `Vector{FlowEdge}`), `source`, `sink`,
`required_flow` (the total teaching load), `labels` (one name per node), and
the dictionaries `faculty_node`, `course_node`, and `completion_node` from names
and course codes to node numbers.
"""
function build_teaching_network(department)
    _check_department(department)
    (; faculty, courses, fixed) = department

    # Number the nodes -
    # Reserve node 1 for the source, then give each network layer a consecutive block.
    faculty_node = Dict(name => 1 + i for (i, name) in enumerate(faculty.name))
    course_node = Dict(code => 1 + nrow(faculty) + j for (j, code) in enumerate(courses.course))
    completion_node = Dict(code => 1 + nrow(faculty) + nrow(courses) + j
        for (j, code) in enumerate(courses.course))
    source, sink = 1, 2 + nrow(faculty) + 2nrow(courses) # two endpoints and three interior layers
    labels = vcat(["source"], faculty.name, courses.course,
        [code * " completion" for code in courses.course], ["sink"])
    fixed_pairs = Set(fixed) # membership determines which option edges require one unit

    # Enforce exact teaching loads -
    edges = FlowEdge[] # insertion order defines columns of A and entries of f, w, ℓ, and c
    for row in eachrow(faculty)
        # Equal bounds force this load into the faculty node; conservation sends it to courses.
        push!(edges, FlowEdge(source, faculty_node[row.name], 0.0, row.load, row.load))
    end
    # Add the available teaching assignments -
    for name in faculty.name, course in courses.course
        score = _score(department, name, course)
        ismissing(score) && continue # blank means no option, even at a high cost
        lower = (name, course) in fixed_pairs ? 1.0 : 0.0 # fixed pairings require one assignment
        cost = get(_costs(department), (name, course), score) # a with_cost(...) change, if any
        # Capacity one prevents assigning the same faculty member to the same course twice.
        push!(edges, FlowEdge(faculty_node[name], course_node[course], cost, lower, 1.0))
    end
    # Enforce course staffing -
    # The course's outgoing flow equals the sum of its incoming faculty assignments.
    for row in eachrow(courses)
        push!(edges, FlowEdge(course_node[row.course], completion_node[row.course], 0.0,
            row.min_faculty, row.max_faculty))
    end
    # Collect completed assignments at the sink -
    # Completion nodes pass on their incoming flow; these edges carry no added score cost.
    for row in eachrow(courses)
        push!(edges, FlowEdge(completion_node[row.course], sink, 0.0, 0.0, row.max_faculty))
    end
    # Return the network and name-to-node maps used to label plots and read assignments -
    return (edges = edges, source = source, sink = sink,
        required_flow = Float64(sum(faculty.load)), labels = labels,
        faculty_node = faculty_node, course_node = course_node, completion_node = completion_node)
end

# --- Scenarios: each returns a modified copy of the department -----------------

"""
    with_load(department, name, load)

Return a copy of `department` in which faculty member `name` has teaching load
`load`. A load of zero models a sabbatical or leave. The input is unchanged.
"""
function with_load(department, name::AbstractString, load::Integer)
    # Copy the table being changed so the baseline load remains available for comparison -
    faculty = copy(department.faculty)
    index = findfirst(==(name), faculty.name)
    isnothing(index) && throw(ArgumentError("unknown faculty member $(name)"))
    faculty.load[index] = load # rebuilding the network will also change required_flow
    changed = (; department..., faculty = faculty) # keep the other fields; replace this table
    _check_department(changed)
    return changed
end

"""
    with_preference(department, name, course, score)

Return a copy of `department` in which the survey score for `name` and
`course` is `score` (0–3, or `missing` for blank). This models a follow-up
conversation that adds or removes an option. Any `with_cost(...)` change for
the same pairing is cleared, so the new score is the edge's cost. The input is
unchanged.
"""
function with_preference(department, name::AbstractString, course::AbstractString, score)
    # Change one entry in a copy of the survey -
    preferences = copy(department.preferences)
    index = findfirst(==(name), preferences.name)
    isnothing(index) && throw(ArgumentError("unknown faculty member $(name)"))
    course in names(preferences) || throw(ArgumentError("unknown course $(course)"))
    preferences[index, course] = score
    # Let the new survey response determine this pairing's cost -
    costs = copy(_costs(department))
    delete!(costs, (String(name), String(course))) # the new score replaces any earlier cost change
    changed = (; department..., preferences = preferences, costs = costs)
    _check_department(changed)
    return changed
end

"""
    with_fixed(department, name, course)

Return a copy of `department` with the additional fixed assignment `name` →
`course`, for example a department mandate. The pairing must have a survey
score. The input is unchanged.
"""
function with_fixed(department, name::AbstractString, course::AbstractString)
    # Append to a new vector; rebuilding sets this option edge's lower bound to one -
    changed = (; department..., fixed = vcat(department.fixed, [(String(name), String(course))]))
    _check_department(changed)
    return changed
end

"""
    with_cost(department, name, course, cost)

Return a copy of `department` in which the edge `name` → `course` has cost
`cost` (score points per assignment) instead of the survey score. Any finite
value is allowed: a value below zero is a bonus, which is how a department can
express a preferred assignment. The pairing must be an option, that is, it must
have a survey score. The input is unchanged.
"""
function with_cost(department, name::AbstractString, course::AbstractString, cost::Real)
    # Override the objective coefficient while keeping the recorded survey response -
    costs = copy(_costs(department))
    costs[(String(name), String(course))] = Float64(cost)
    changed = (; department..., costs = costs)
    _check_department(changed)
    return changed
end

"""
    with_staffing(department, course, min_faculty, max_faculty)

Return a copy of `department` in which `course` needs at least `min_faculty`
and allows at most `max_faculty` instructors. The input is unchanged.
"""
function with_staffing(department, course::AbstractString, min_faculty::Integer, max_faculty::Integer)
    # Change one course's staffing interval in a copy of the course table -
    courses = copy(department.courses)
    index = findfirst(==(course), courses.course)
    isnothing(index) && throw(ArgumentError("unknown course $(course)"))
    # Rebuilding transfers these limits to the course's outgoing staffing edge.
    courses.min_faculty[index] = min_faculty
    courses.max_faculty[index] = max_faculty
    changed = (; department..., courses = courses)
    _check_department(changed)
    return changed
end

# --- Linear program ------------------------------------------------------------

"""
    flow_formulation(edges::AbstractVector{FlowEdge}, source::Integer,
        sink::Integer, required_flow::Real)

Assemble node-edge incidence data for a minimum-cost flow model using inflow
minus outflow. This function returns model data; it does not solve the model.

# Returns
A named tuple with `A`, `b`, `w`, `lower`, `capacity`, and `vertices`:
- `vertices` lists the node identifiers in ascending order; it defines row order.
- `A` has one row per node and one column per edge, in input order. A column
  has -1 at the edge's source, +1 at its target, and zeros elsewhere.
- `b` is `-required_flow` at the source, `required_flow` at the sink, and zero
  at intermediate nodes.
- `w` contains the cost per unit of flow on each edge (the lecture's w_j).
- `lower` and `capacity` contain the edge bounds ℓ_j and c_j, in flow units.

The source and sink must be distinct nodes in the network, and the required
flow must be finite and nonnegative. Whether that flow can be delivered within
the bounds is decided by the solver, not here.
"""
function flow_formulation(edges::AbstractVector{FlowEdge}, source::Integer, sink::Integer, required_flow::Real)
    # Check the delivery request -
    source_id, sink_id = Int64(source), Int64(sink)
    source_id == sink_id && throw(ArgumentError("source and sink must differ"))
    isfinite(required_flow) && required_flow >= 0 || throw(ArgumentError("required flow must be finite and nonnegative"))
    # Map graph identifiers to matrix rows -
    # The general assembly helper allows gaps in node numbers; a row is an array position.
    vertices = sort!(collect(Set(vcat([e.source for e in edges], [e.target for e in edges]))))
    source_id in vertices || throw(ArgumentError("source is not in the graph"))
    sink_id in vertices || throw(ArgumentError("sink is not in the graph"))
    row = Dict(vertex => i for (i, vertex) in enumerate(vertices)) # node identifier => row index

    # Assemble the node-edge incidence matrix -
    A = zeros(Float64, length(vertices), length(edges)) # rows: nodes; columns: edges
    for (j, edge) in enumerate(edges)
        A[row[edge.source], j] = -1.0 # flow leaves the edge's source
        A[row[edge.target], j] = 1.0 # flow enters the edge's target
    end
    # Prescribe the node balances using the same inflow-minus-outflow convention -
    b = zeros(Float64, length(vertices)) # zero at intermediate nodes means inflow equals outflow
    b[row[source_id]] = -required_flow
    b[row[sink_id]] = required_flow
    # Keep all edge vectors in the same order as the columns of A -
    return (A = A, b = b, w = [e.cost for e in edges], lower = [e.lower for e in edges],
        capacity = [e.upper for e in edges], vertices = vertices)
end

"""
    solve_flow_lp(network, A, b, w, lower, capacity)

Solve the minimum-cost flow linear program with JuMP and GLPK:

    minimize sum_j w_j f_j  subject to  A f = b,  ℓ_j <= f_j <= c_j,

where `lower` holds the lower bounds ℓ_j and `capacity` the capacities c_j.

The arrays are the ones assembled in the notebook: `A` has one row per node
(row `i` is node `i`) and one column per edge in `network.edges` order, and `b`,
`w`, `lower`, and `capacity` follow the same orders. `network` supplies the edge
endpoints for the returned flow dictionary.

# Returns
A named tuple with `status` (the solver's termination status), `optimal`,
`flow` (a dictionary from `(source, target)` pairs to flows), `vector` (flows
in edge order), `cost`, and `formulation` (the arrays, with `vertices`). When
the status is not `OPTIMAL`, for example `INFEASIBLE`, the flow fields and the
cost are `nothing`: there is no schedule to read. Check the status first.
Independent feasibility and cost checks remain the caller's task.
"""
function solve_flow_lp(network, A::AbstractMatrix, b::AbstractVector, w::AbstractVector,
        lower::AbstractVector, capacity::AbstractVector)
    # Check array dimensions -
    n = length(network.edges) # one decision variable for each directed edge
    size(A, 2) == n == length(w) == length(lower) == length(capacity) ||
        throw(DimensionMismatch("A, w, and the bounds need one column or entry per edge"))
    size(A, 1) == length(b) || throw(DimensionMismatch("b needs one entry per row of A"))
    # Define the linear program -
    model = JuMP.Model(GLPK.Optimizer) # JuMP describes the model; GLPK solves it
    JuMP.set_silent(model) # omit the solver's iteration log from the notebook output
    # x[j] represents f_j in the lab; these are continuous, bounded flow variables.
    x = JuMP.@variable(model, lower[j] <= x[j = 1:n] <= capacity[j])
    JuMP.@constraint(model, A * x .== b) # .== creates one balance equality for each node
    JuMP.@objective(model, Min, sum(w[j] * x[j] for j in 1:n)) # total score cost, wᵀf

    # Solve and inspect the termination status before requesting any flow values -
    JuMP.optimize!(model)
    status = JuMP.termination_status(model)
    formulation = (A = A, b = b, w = w, lower = lower, capacity = capacity, vertices = collect(1:size(A, 1)))
    if status != MOI.OPTIMAL
        # An infeasible model has no schedule; other nonoptimal statuses are also withheld.
        return (status = status, optimal = false, flow = nothing, vector = nothing,
            cost = nothing, formulation = formulation)
    end
    # Extract the optimal flows in two forms -
    vector = JuMP.value.(x) # edge order for matrix checks and objective calculations
    # Endpoint pairs support named assignment lookups; the teaching graph has no parallel edges.
    flow = Dict((edge.source, edge.target) => vector[j] for (j, edge) in enumerate(network.edges))
    return (status = status, optimal = true, flow = flow, vector = vector,
        cost = JuMP.objective_value(model), formulation = formulation)
end

"""
    solve_min_cost_flow(network)

Assemble the arrays for `network` with `flow_formulation(...)` and solve them
with `solve_flow_lp(...)`. Used for the what-if scenarios, where the notebook
does not rebuild the arrays by hand. Returns the same named tuple as
`solve_flow_lp(...)`.
"""
function solve_min_cost_flow(network)
    # Reassemble every array after a scenario changes edges, bounds, costs, or total load -
    form = flow_formulation(network.edges, network.source, network.sink, network.required_flow)
    # The notebook solver uses node i as row i; require this numbering in its network input.
    form.vertices == collect(1:length(form.vertices)) ||
        throw(ArgumentError("network nodes must be numbered 1, 2, ..., n"))
    return solve_flow_lp(network, form.A, form.b, form.w, form.lower, form.capacity)
end

"""
    validate_flow_solution(edges::AbstractVector{FlowEdge}, result; atol::Real = 1e-8)

Recompute node balances and total cost from an optimal result's flow vector.

Returns the flags `valid`, `bounds_ok`, `balance_ok`, and `objective_ok`, plus
`maximum_balance_residual` and `recomputed_cost`. The balances are accumulated
directly from the edge endpoints, not from the solver's incidence matrix. These
checks establish numerical feasibility and objective consistency, not
optimality or integrality. `atol` is an absolute tolerance in flow units
(assignments) and cost units (score points).
"""
function validate_flow_solution(edges::AbstractVector{FlowEdge}, result; atol::Real = 1e-8)
    # Check that flows and a meaningful absolute tolerance are available -
    isfinite(atol) && atol >= 0 || throw(ArgumentError("atol must be finite and nonnegative"))
    result.optimal || throw(ArgumentError("only an optimal result has flows to validate"))
    length(edges) == length(result.vector) || throw(DimensionMismatch("one flow value is required per edge"))
    # Recompute net inflow directly from the graph -
    # This avoids reusing A, so an incorrectly assembled incidence matrix can be detected.
    vertices = result.formulation.vertices
    row = Dict(vertex => i for (i, vertex) in enumerate(vertices))
    net_inflow = zeros(Float64, length(vertices))
    for (i, edge) in enumerate(edges)
        net_inflow[row[edge.source]] -= result.vector[i] # subtract flow where the edge begins
        net_inflow[row[edge.target]] += result.vector[i] # add the same flow where it ends
    end
    # Compare the flows with the bounds, prescribed balances, and reported objective -
    maximum_balance_residual = maximum(abs, net_inflow - result.formulation.b; init = 0.0) # flow units
    recomputed_cost = dot([e.cost for e in edges], result.vector) # wᵀf, in score points
    bounds_ok = all(edge.lower - atol <= result.vector[i] <= edge.upper + atol
        for (i, edge) in enumerate(edges))
    balance_ok = maximum_balance_residual <= atol
    objective_ok = isapprox(recomputed_cost, result.cost; atol = atol, rtol = 0.0) # absolute tolerance only
    return (valid = bounds_ok && balance_ok && objective_ok,
        bounds_ok = bounds_ok, balance_ok = balance_ok, objective_ok = objective_ok,
        maximum_balance_residual = maximum_balance_residual, recomputed_cost = recomputed_cost)
end

# --- Reading the schedule --------------------------------------------------------

"""
    teaching_schedule(department, network, result; atol::Real = 1e-8)

List the faculty–course assignments in an optimal result.

Returns a `DataFrame` with one row per faculty → course edge carrying flow
above `atol`, in course order: `course`, `title`, `name`, `score`, `flow`, and
`fixed` (whether the department fixed that assignment). Flows are reported as
returned, without rounding; checking that they are whole assignments is a
separate step.
"""
function teaching_schedule(department, network, result; atol::Real = 1e-8)
    result.optimal || throw(ArgumentError("an infeasible or unsolved model has no schedule"))
    # Allocate the assignment table -
    fixed_pairs = Set(department.fixed) # mark department mandates in the displayed schedule
    schedule = DataFrame(course = String[], title = String[], name = String[],
        score = Int[], flow = Float64[], fixed = Bool[])
    # Read only faculty-to-course flows; other layers carry the same assignments onward -
    for course_row in eachrow(department.courses), name in department.faculty.name
        pair = (network.faculty_node[name], network.course_node[course_row.course])
        value = get(result.flow, pair, 0.0) # an unavailable pairing has no edge and contributes zero
        value > atol || continue # omit unused edges and numerical values near zero
        # Keep the returned flow unrounded and the original survey score for interpretation.
        push!(schedule, (course_row.course, course_row.title, name,
            _score(department, name, course_row.course), value,
            (name, course_row.course) in fixed_pairs))
    end
    return schedule
end

"""
    schedule_checks(department, schedule; atol::Real = 1e-8)

Count each faculty member's assignments and each course's staffing in a
schedule and compare them with the department rules.

Returns a named tuple with two `DataFrame`s: `loads` (`name`, `required`,
`assigned`, `ok`) and `staffing` (`course`, `min_faculty`, `assigned`,
`max_faculty`, `ok`), plus `all_ok`. Assigned counts add the schedule's flow
values, so they are whole numbers only for a whole-number schedule. `atol` is
the absolute tolerance in assignments for load and staffing comparisons.
"""
function schedule_checks(department, schedule; atol::Real = 1e-8)
    # Count assignments from flows, including zero for a faculty member or course with no rows -
    assigned_to(name) = sum(schedule.flow[schedule.name .== name]; init = 0.0)
    staffed(course) = sum(schedule.flow[schedule.course .== course]; init = 0.0)
    # Compare each faculty member's assigned count with the exact teaching load -
    loads = DataFrame(name = department.faculty.name, required = department.faculty.load,
        assigned = assigned_to.(department.faculty.name))
    loads.ok = abs.(loads.assigned .- loads.required) .<= atol
    # Compare each course's assigned count with both staffing limits -
    staffing = DataFrame(course = department.courses.course,
        min_faculty = department.courses.min_faculty,
        assigned = staffed.(department.courses.course),
        max_faculty = department.courses.max_faculty)
    staffing.ok = (staffing.min_faculty .- atol .<= staffing.assigned) .& # both tests must hold per course
        (staffing.assigned .<= staffing.max_faculty .+ atol)
    return (loads = loads, staffing = staffing, all_ok = all(loads.ok) && all(staffing.ok))
end

"""
    assignments_by_faculty(department, schedule)

Summarize a schedule from `teaching_schedule(...)` by faculty member.

Returns a `DataFrame` with one row per faculty member in `Faculty.csv` order:
`name`, `load`, `courses` (the assigned course codes joined with commas, or
`"none"`), and `scores` (the matching survey scores, in the same order). This is
the teaching-assignment table a department would publish.
"""
function assignments_by_faculty(department, schedule)
    # Start with every faculty member, including those with no assignments -
    rows = DataFrame(name = department.faculty.name, load = department.faculty.load)
    picks(name) = schedule[schedule.name .== name, :] # select this faculty member's assignment rows
    # Join course codes and survey scores in the same order for side-by-side reading.
    # The local p holds the selected rows within each comprehension iteration.
    rows.courses = [(p = picks(name); nrow(p) == 0 ? "none" : join(p.course, ", ")) for name in rows.name]
    rows.scores = [(p = picks(name); nrow(p) == 0 ? "" : join(string.(p.score), ", ")) for name in rows.name]
    return rows
end

end
