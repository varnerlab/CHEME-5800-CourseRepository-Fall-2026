# L5d is walked through in class, so this file ships the complete implementation.
# It matches src/Compute-solution.jl apart from this header. After class, try
# rewriting build_teaching_network(...) from its docstring and compare.
# Functions for the L5d teaching-assignment lab. Load them through Include.jl.
#
# The file follows the calculation: read the department data, build a network,
# make scenario copies, solve the linear program, and read/check the schedule.
# A NamedTuple groups values under names such as department.faculty or network.edges.
# Functions whose names start with _ are helpers used by the other functions here.

# --- Department data ---------------------------------------------------------

"""
    read_department(folder::AbstractString)

Read the department tables from `folder` and check that they agree.

# Files
- `Faculty.csv`: columns `name` and `load`. The load is the exact number of
  courses the faculty member teaches this semester.
- `Courses.csv`: columns `course`, `min_faculty`, `max_faculty`, and `title`.
  The staffing bounds count faculty assigned to the course.
- `Preferences.csv`: a `name` column followed by one column per course code.
  Each entry is a survey score from 0 (prepared to teach) to 3 (needs
  significant support). A blank receives the default score 3, so the pairing
  remains available at the highest survey cost.

# Returns
A named tuple with `faculty`, `courses`, `preferences`, and `costs`.
The first three are `DataFrame`s in file order; `preferences` replaces blank
entries with 3. `costs` starts empty; `with_cost(...)` fills it with costs
that replace survey scores.

# Checks
Names and course codes must be unique and must agree across the files. Loads
and staffing bounds must be nonnegative integers with `min_faculty <=
max_faculty`. Input scores must be 0, 1, 2, 3, or blank; loaded scores are 0–3.
An `ArgumentError` reports the first problem.
"""
function read_department(folder::AbstractString)

    # Check the input folder before trying to read any tables -
    # throw(...) stops the calculation and reports the problem to the caller.
    if !isdir(folder)
        throw(ArgumentError("department folder does not exist: $(folder)"))
    end

    # Read each file into a DataFrame: a table with named columns -
    # joinpath(...) builds a file path; stripwhitespace removes spaces around entries.
    faculty = CSV.read(joinpath(folder, "Faculty.csv"), DataFrame; stripwhitespace = true)
    courses = CSV.read(joinpath(folder, "Courses.csv"), DataFrame; stripwhitespace = true)
    preferences = CSV.read(joinpath(folder, "Preferences.csv"), DataFrame; stripwhitespace = true)

    # Store names and course codes as ordinary strings for later table and dictionary lookups -
    # Vector{String}(...) copies a column into a vector whose entries are strings.
    faculty.name = Vector{String}(faculty.name)
    courses.course = Vector{String}(courses.course)
    courses.title = Vector{String}(courses.title)
    preferences.name = Vector{String}(preferences.name)

    # Build a complete score column for each course -
    # The first column contains faculty names; the remaining columns contain scores.
    # A blank response becomes the highest survey cost, keeping that pairing available.
    course_columns = names(preferences)[2:end]
    for course in course_columns
        scores = zeros(Int, nrow(preferences)) # one whole-number score per faculty member

        for i in 1:nrow(preferences)
            score = preferences[i, course] # row i: faculty member; column: course code

            if ismissing(score)
                scores[i] = 3
            elseif score isa Real && score in 0:3
                scores[i] = Int(score)
            else
                throw(ArgumentError("scores for $(course) must be 0, 1, 2, or 3"))
            end
        end

        # [!, course] replaces the entire DataFrame column with the completed vector.
        preferences[!, course] = scores
    end

    # Group the inputs in a named tuple so callers can use department.faculty, etc. -
    # costs starts empty. A scenario can store a replacement cost under a two-part key:
    # (faculty name, course code). Each replacement is measured in score points per assignment.
    department = (
        faculty = faculty,
        courses = courses,
        preferences = preferences,
        costs = Dict{Tuple{String,String},Float64}(),
    )

    _check_department(department) # confirm that the tables describe the same faculty and courses
    return department
end

# Validate the department's data, including changes made by the scenario helpers.
# These checks establish valid inputs; the solver decides whether a schedule exists.
function _check_department(department::NamedTuple)

    # Read the tables from their named fields -
    # These local names refer to the existing tables; this function only reads them.
    faculty = department.faculty
    courses = department.courses
    preferences = department.preferences

    # Duplicate names would make a faculty or course lookup ambiguous.
    # allunique(...) is true only when every entry appears once.
    if !allunique(faculty.name)
        throw(ArgumentError("faculty names must be unique"))
    end

    if !allunique(courses.course)
        throw(ArgumentError("course codes must be unique"))
    end

    # Teaching loads count assignments, so negative or fractional loads are invalid.
    for load in faculty.load
        if !(load isa Integer && load >= 0)
            throw(ArgumentError("every load must be a nonnegative integer"))
        end
    end

    # Require a valid staffing interval for every course -
    # eachrow(...) visits one table row at a time; row.min_faculty reads a named entry.
    for row in eachrow(courses)
        if !(row.min_faculty isa Integer && row.max_faculty isa Integer)
            throw(ArgumentError("staffing bounds for $(row.course) must be integers"))
        end

        if !(0 <= row.min_faculty <= row.max_faculty)
            throw(ArgumentError("staffing bounds for $(row.course) must satisfy 0 ≤ min ≤ max"))
        end
    end

    # Match survey rows and columns to the order used to number the network nodes -
    # If the order differs, a score could be applied to the wrong faculty–course pair.
    if preferences.name != faculty.name
        throw(ArgumentError("preference rows must list the faculty in the same order as Faculty.csv"))
    end

    if names(preferences)[2:end] != courses.course
        throw(ArgumentError("preference columns must list the courses in the same order as Courses.csv"))
    end

    for course in courses.course
        for score in preferences[!, course]
            if !(score isa Real && score in 0:3)
                throw(ArgumentError("scores for $(course) must be 0, 1, 2, or 3"))
            end
        end
    end

    # Check costs supplied by with_cost(...); negative costs are allowed -
    for pair in keys(department.costs)
        name = pair[1] # first part of the key: faculty name
        course = pair[2] # second part of the key: course code
        cost = department.costs[pair]

        if !(name in faculty.name && course in courses.course)
            throw(ArgumentError("a cost must name a known faculty-course pairing: $(name) → $(course)"))
        end

        if !isfinite(cost)
            throw(ArgumentError("the cost for $(name) → $(course) must be finite"))
        end
    end

    return nothing # completing the checks without an error means the inputs are valid
end

# Read one survey entry after the caller has checked the faculty and course names.
function _score(department::NamedTuple, name::AbstractString, course::AbstractString)

    # Find the faculty member's survey row, then read the requested course column -
    # Names are unique, so the first matching row is the only matching row.
    preferences = department.preferences
    for i in 1:nrow(preferences)
        if preferences.name[i] == name
            return preferences[i, course]
        end
    end

    throw(ArgumentError("unknown faculty member $(name)"))
end

"""
    staffing_totals(department::NamedTuple)

Compare the total teaching load with the total staffing the courses require
and allow. This is the check we make before solving.

Returns a named tuple with `total_load`, `total_min`, `total_max`, and
`totals_ok`. Every assignment uses one unit of some faculty member's load and
one staffing position in some course, so a schedule can exist only when
`total_min <= total_load <= total_max`. Passing this check does not guarantee
a schedule: it ignores which faculty can teach which courses.
"""
function staffing_totals(department::NamedTuple)

    # Compare the required teaching load with the courses' total staffing limits -
    total_load = sum(department.faculty.load) # F: assignments the faculty must teach
    total_min = sum(department.courses.min_faculty) # minimum assignments needed by the courses
    total_max = sum(department.courses.max_faculty) # maximum assignments the courses can accept

    return (
        total_load = total_load,
        total_min = total_min,
        total_max = total_max,
        totals_ok = total_min <= total_load <= total_max,
    )
end

"""
    build_teaching_network(department::NamedTuple)

Translate the department rules into a flow network with lower and upper bounds.

Node `1` is the source, the faculty follow in file order, then the courses in
file order, then one completion node per course in the same order, and the last
node is the sink. As in the L5a and L5b networks, each course's completion node
passes its flow on to the sink. The edges encode the rules:

| Rule | Edge | Lower bound ℓ | Capacity c | Cost w |
|---|---|---|---|---|
| Exact teaching load | source → faculty | load | load | 0 |
| Survey score 0–3 | faculty → course | 0 | 1 | score, or a `with_cost` value |
| Blank input score | faculty → course | 0 | 1 | default score 3 |
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
function build_teaching_network(department::NamedTuple)

    # Read the checked tables and count the faculty and courses -
    _check_department(department)
    faculty = department.faculty
    courses = department.courses
    number_of_faculty = nrow(faculty)
    number_of_courses = nrow(courses)

    # Number the nodes in order: source, faculty, courses, completion nodes, sink -
    # Each course has its own completion node. The extra two nodes are source and sink.
    # Identifiers run from 1 to sink, so a node identifier is also its array position.
    source = 1
    sink = 2 + number_of_faculty + 2 * number_of_courses
    labels = fill("", sink) # one display label per node, initially an empty string
    labels[source] = "source"
    labels[sink] = "sink"

    # Dictionaries translate a faculty name or course code into its node identifier -
    faculty_node = Dict{String,Int}()
    course_node = Dict{String,Int}()
    completion_node = Dict{String,Int}()

    for i in 1:number_of_faculty
        name = faculty.name[i]
        node = source + i # faculty nodes immediately follow the source
        faculty_node[name] = node
        labels[node] = name
    end

    for j in 1:number_of_courses
        course = courses.course[j]
        course_id = source + number_of_faculty + j
        completion_id = source + number_of_faculty + number_of_courses + j

        course_node[course] = course_id
        completion_node[course] = completion_id
        labels[course_id] = course
        labels[completion_id] = course * " completion" # * joins strings in Julia
    end

    # Enforce exact teaching loads on source → faculty edges -
    # FlowEdge(from, to, cost, lower, upper) stores one edge and its model inputs.
    # push!(...) appends an edge. This insertion order will also order the columns of A
    # and the entries of the flow, cost, and bound vectors.
    edges = FlowEdge[] # start with an empty vector of edge records
    for row in eachrow(faculty)
        load_edge = FlowEdge(source, faculty_node[row.name], 0.0, row.load, row.load)
        push!(edges, load_edge) # equal bounds require the faculty member's full load
    end

    # Add one possible assignment for every faculty–course pair -
    # The survey score is the cost unless with_cost(...) supplied a replacement.
    for name in faculty.name
        for course in courses.course
            cost = _score(department, name, course)
            pair = (name, course)
            if haskey(department.costs, pair)
                cost = department.costs[pair]
            end

            # A lower bound of zero leaves the choice to the solver. Capacity one
            # prevents assigning the same faculty member to the same course twice.
            assignment_edge = FlowEdge(faculty_node[name], course_node[course], cost, 0.0, 1.0)
            push!(edges, assignment_edge)
        end
    end

    # Apply staffing limits to the course's total incoming assignments -
    # Conservation sends all faculty assignments for a course through this one edge.
    # Its lower and upper bounds therefore control the size of the whole teaching team.
    for row in eachrow(courses)
        staffing_edge = FlowEdge(
            course_node[row.course],
            completion_node[row.course],
            0.0, # staffing edges add no preference cost
            row.min_faculty,
            row.max_faculty,
        )
        push!(edges, staffing_edge)
    end

    # Pass the same assignments from each completion node to the sink -
    # These edges complete the paths without adding cost or tightening the staffing limit.
    for row in eachrow(courses)
        completion_edge = FlowEdge(completion_node[row.course], sink, 0.0, 0.0, row.max_faculty)
        push!(edges, completion_edge)
    end

    # Return the edge list, endpoint identifiers, and maps used to interpret the solution -
    # F is fixed by the faculty loads; the solver chooses which courses receive those assignments.
    return (
        edges = edges,
        source = source,
        sink = sink,
        required_flow = Float64(sum(faculty.load)), # F: total required assignments
        labels = labels,
        faculty_node = faculty_node,
        course_node = course_node,
        completion_node = completion_node,
    )
end

# --- Scenarios: each returns a modified copy of the department -----------------

"""
    with_load(department::NamedTuple, name::AbstractString, load::Integer)

Return a copy of `department` in which faculty member `name` has teaching load
`load`. A load of zero models a sabbatical or leave. The input is unchanged.
"""
function with_load(department::NamedTuple, name::AbstractString, load::Integer)

    # Copy the table that will change so the starting department keeps its original loads -
    faculty = copy(department.faculty)

    # Search for the faculty member's row -
    # Table rows start at 1, so zero means that no matching row has been found.
    index = 0
    for i in 1:nrow(faculty)
        if faculty.name[i] == name
            index = i
            break # the names are unique; no further search is needed
        end
    end

    if index == 0
        throw(ArgumentError("unknown faculty member $(name)"))
    end

    # Build a department record using the revised load table and the unchanged inputs -
    # Rebuilding the network from this record also changes its required total flow.
    faculty.load[index] = load
    changed = (
        faculty = faculty,
        courses = department.courses,
        preferences = department.preferences,
        costs = department.costs,
    )

    _check_department(changed) # apply the same input rules used when reading the files
    return changed
end

"""
    with_preference(department::NamedTuple, name::AbstractString,
        course::AbstractString, score::Union{Real,Missing})

Return a copy of `department` in which the survey score for `name` and
`course` is `score` (0–3, or `missing` to restore the default 3). This models a
follow-up conversation that changes an assignment's cost. Any `with_cost(...)` change for
the same pairing is cleared, so the new score is the edge's cost. The input is
unchanged.
"""
function with_preference(
    department::NamedTuple,
    name::AbstractString,
    course::AbstractString,
    score::Union{Real,Missing}, # accept a number or missing, which restores the default
)

    # Copy the survey so changing this response leaves the starting data available -
    preferences = copy(department.preferences)
    index = 0
    for i in 1:nrow(preferences)
        if preferences.name[i] == name
            index = i
            break
        end
    end

    if index == 0
        throw(ArgumentError("unknown faculty member $(name)"))
    end

    if !(course in department.courses.course)
        throw(ArgumentError("unknown course $(course)"))
    end

    # Set the new response, using the default score when the response is blank -
    if ismissing(score)
        preferences[index, course] = 3
    else
        preferences[index, course] = score
    end

    # Remove any cost override for this pair so the new survey score determines its cost -
    # Copying this dictionary keeps the original department's overrides unchanged too.
    costs = copy(department.costs)
    pair = (String(name), String(course))
    if haskey(costs, pair)
        delete!(costs, pair)
    end

    changed = (
        faculty = department.faculty,
        courses = department.courses,
        preferences = preferences,
        costs = costs,
    )

    _check_department(changed)
    return changed
end

"""
    with_cost(department::NamedTuple, name::AbstractString, course::AbstractString, cost::Real)

Return a copy of `department` in which the edge `name` → `course` has cost
`cost` (score points per assignment) instead of the survey score. Any finite
value is allowed: a value below zero is a bonus, which is how a department can
express a preferred assignment. The faculty member and course must exist;
the pairing may have a supplied or default score. The input is unchanged.
"""
function with_cost(
    department::NamedTuple,
    name::AbstractString,
    course::AbstractString,
    cost::Real,
)

    # Copy the cost dictionary and replace the cost for this faculty–course pair -
    # The survey table stays unchanged; the network builder gives this override priority.
    costs = copy(department.costs)
    pair = (String(name), String(course))
    costs[pair] = Float64(cost) # score points per assignment; a negative value is a bonus

    changed = (
        faculty = department.faculty,
        courses = department.courses,
        preferences = department.preferences,
        costs = costs,
    )

    _check_department(changed) # also checks that this pair names a known faculty member and course
    return changed
end

"""
    with_staffing(department::NamedTuple, course::AbstractString,
        min_faculty::Integer, max_faculty::Integer)

Return a copy of `department` in which `course` needs at least `min_faculty`
and allows at most `max_faculty` instructors. The input is unchanged.
"""
function with_staffing(
    department::NamedTuple,
    course::AbstractString,
    min_faculty::Integer,
    max_faculty::Integer,
)

    # Copy the staffing table and locate the course whose bounds will change -
    courses = copy(department.courses)
    index = 0
    for i in 1:nrow(courses)
        if courses.course[i] == course
            index = i
            break
        end
    end

    if index == 0
        throw(ArgumentError("unknown course $(course)"))
    end

    # Store the revised interval; rebuilding transfers it to the course's staffing edge -
    courses.min_faculty[index] = min_faculty
    courses.max_faculty[index] = max_faculty
    changed = (
        faculty = department.faculty,
        courses = courses,
        preferences = department.preferences,
        costs = department.costs,
    )

    _check_department(changed) # rejects negative bounds and a minimum greater than the maximum
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
function flow_formulation(
    edges::AbstractVector{FlowEdge},
    source::Integer,
    sink::Integer,
    required_flow::Real,
)

    # Check the requested source-to-sink flow before allocating the model arrays -
    source_id = Int64(source)
    sink_id = Int64(sink)
    if source_id == sink_id
        throw(ArgumentError("source and sink must differ"))
    end

    if !(isfinite(required_flow) && required_flow >= 0)
        throw(ArgumentError("required flow must be finite and nonnegative"))
    end

    # Collect the node identifiers used by the edges -
    # A node can appear on several edges. unique(...) removes these repeated identifiers,
    # and sort!(...) puts the remaining identifiers in ascending order.
    vertices = Int64[]
    for edge in edges
        push!(vertices, edge.source)
        push!(vertices, edge.target)
    end
    vertices = unique(vertices)
    sort!(vertices)

    if !(source_id in vertices)
        throw(ArgumentError("source is not in the graph"))
    end

    if !(sink_id in vertices)
        throw(ArgumentError("sink is not in the graph"))
    end

    # Map each node identifier to its row in the arrays -
    # The teaching network numbers its nodes consecutively, but this helper also accepts
    # gaps in the numbering. A dictionary tells us which row belongs to each identifier.
    number_of_nodes = length(vertices)
    number_of_edges = length(edges)
    row = Dict{Int64,Int}()
    for i in 1:number_of_nodes
        row[vertices[i]] = i
    end

    # Assemble one incidence column per edge -
    # Column j has -1 where edge j begins and +1 where it ends. All other entries stay zero.
    # Multiplying A by a flow vector therefore computes incoming minus outgoing flow.
    A = zeros(Float64, number_of_nodes, number_of_edges)
    for j in 1:number_of_edges
        edge = edges[j]
        source_row = row[edge.source]
        target_row = row[edge.target]
        A[source_row, j] = -1.0
        A[target_row, j] = 1.0
    end

    # Prescribe the net flow required at each node -
    # The source supplies flow and the sink receives it. Every intermediate node has a
    # zero entry, requiring its incoming and outgoing totals to balance.
    b = zeros(Float64, number_of_nodes)
    b[row[source_id]] = -required_flow
    b[row[sink_id]] = required_flow

    # Store each edge's cost and bounds in the same position as its column in A -
    w = zeros(Float64, number_of_edges)
    lower = zeros(Float64, number_of_edges)
    capacity = zeros(Float64, number_of_edges)
    for j in 1:number_of_edges
        edge = edges[j]
        w[j] = edge.cost # cost per unit of flow
        lower[j] = edge.lower # ℓ_j: required minimum flow
        capacity[j] = edge.upper # c_j: allowed maximum flow
    end

    return (
        A = A,
        b = b,
        w = w,
        lower = lower,
        capacity = capacity,
        vertices = vertices,
    )
end

"""
    solve_flow_lp(network::NamedTuple, A::AbstractMatrix,
        b::AbstractVector, w::AbstractVector,
        lower::AbstractVector, capacity::AbstractVector)

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
function solve_flow_lp(
    network::NamedTuple,
    A::AbstractMatrix,
    b::AbstractVector,
    w::AbstractVector,
    lower::AbstractVector,
    capacity::AbstractVector,
)

    # Check that each array has the size required by the network -
    # Each edge needs a column in A, a cost, and two bounds. Each row of A needs one
    # prescribed node balance in b. These checks catch mismatched arrays before solving.
    number_of_edges = length(network.edges)
    number_of_nodes = size(A, 1)

    if size(A, 2) != number_of_edges
        throw(DimensionMismatch("A needs one column per edge"))
    end

    if length(w) != number_of_edges
        throw(DimensionMismatch("w needs one cost per edge"))
    end

    if length(lower) != number_of_edges || length(capacity) != number_of_edges
        throw(DimensionMismatch("the bounds need one entry per edge"))
    end

    if length(b) != number_of_nodes
        throw(DimensionMismatch("b needs one entry per row of A"))
    end

    # Create a JuMP model and choose GLPK as the solver -
    # The @variable, @constraint, and @objective commands describe the optimization
    # problem. They do not compute a solution; optimize!(...) does that later.
    model = JuMP.Model(GLPK.Optimizer)
    JuMP.set_silent(model) # omit the solver's iteration log from notebook output

    # Create one continuous flow variable per edge and apply its lower and upper bounds -
    # x[j] is f_j in the lab. A load edge with equal bounds fixes the faculty member's load;
    # an assignment edge with bounds zero and one lets the solver choose that pairing.
    JuMP.@variable(model, x[1:number_of_edges])
    for j in 1:number_of_edges
        JuMP.set_lower_bound(x[j], lower[j])
        JuMP.set_upper_bound(x[j], capacity[j])
    end

    # Add a balance equation for each node -
    # The sum adds A[i,j] * x[j] over all edges j for the current node i.
    # The incidence signs make this incoming minus outgoing flow, which must equal b[i].
    for i in 1:number_of_nodes
        JuMP.@constraint(model, sum(A[i, j] * x[j] for j in 1:number_of_edges) == b[i])
    end

    # Minimize the total cost: cost per assignment multiplied by assigned flow on each edge -
    # Only faculty → course edges have preference costs, so an assignment is charged once.
    JuMP.@objective(model, Min, sum(w[j] * x[j] for j in 1:number_of_edges))

    # Solve the model and retain its input arrays for later checks -
    JuMP.optimize!(model)
    status = JuMP.termination_status(model)
    formulation = (
        A = A,
        b = b,
        w = w,
        lower = lower,
        capacity = capacity,
        vertices = collect(1:number_of_nodes), # node i corresponds to row i in this model
    )

    # Stop here unless the solver reports an optimal solution -
    # For example, an infeasible model has no schedule to interpret. Returning nothing
    # for its flows and cost prevents those missing results from being mistaken for zeros.
    if status != MathOptInterface.OPTIMAL
        return (
            status = status,
            optimal = false,
            flow = nothing,
            vector = nothing,
            cost = nothing,
            formulation = formulation,
        )
    end

    # Read the solved flows as numbers and store them in two useful forms -
    # vector[j] follows the edge order used by A. flow[(source, target)] lets the schedule
    # reader look up a named pairing after translating the names into node identifiers.
    vector = zeros(Float64, number_of_edges)
    flow = Dict{Tuple{Int64,Int64},Float64}()
    for j in 1:number_of_edges
        edge = network.edges[j]
        vector[j] = JuMP.value(x[j]) # the value chosen by the solver for this edge
        pair = (edge.source, edge.target)
        flow[pair] = vector[j] # the teaching network has only one edge for each endpoint pair
    end

    return (
        status = status,
        optimal = true,
        flow = flow,
        vector = vector,
        cost = JuMP.objective_value(model),
        formulation = formulation,
    )
end

"""
    solve_min_cost_flow(network::NamedTuple)

Assemble the arrays for `network` with `flow_formulation(...)` and solve them
with `solve_flow_lp(...)`. Used for the what-if scenarios, where the notebook
does not rebuild the arrays by hand. Returns the same named tuple as
`solve_flow_lp(...)`.
"""
function solve_min_cost_flow(network::NamedTuple)

    # Rebuild every array from the current network before solving -
    # A scenario may change costs, bounds, or total teaching load. Rebuilding prevents
    # the solver from accidentally using any array left over from the starting schedule.
    form = flow_formulation(network.edges, network.source, network.sink, network.required_flow)

    # Require the numbering used by solve_flow_lp(...): node i must occupy row i -
    for i in 1:length(form.vertices)
        if form.vertices[i] != i
            throw(ArgumentError("network nodes must be numbered 1, 2, ..., n"))
        end
    end

    return solve_flow_lp(network, form.A, form.b, form.w, form.lower, form.capacity)
end

"""
    validate_flow_solution(edges::AbstractVector{FlowEdge}, result::NamedTuple; atol::Real = 1e-8)

Recompute node balances and total cost from an optimal result's flow vector.

Returns the flags `valid`, `bounds_ok`, `balance_ok`, and `objective_ok`, plus
`maximum_balance_residual` and `recomputed_cost`. The balances are accumulated
directly from the edge endpoints, not from the solver's incidence matrix. These
checks establish numerical feasibility and objective consistency, not
optimality or integrality. `atol` is an absolute tolerance in flow units
(assignments) and cost units (score points).
"""
function validate_flow_solution(
    edges::AbstractVector{FlowEdge},
    result::NamedTuple;
    atol::Real = 1e-8,
)

    # Require an optimal result and a valid comparison tolerance -
    # atol allows small floating-point errors in flows and cost. It does not change any flow.
    if !(isfinite(atol) && atol >= 0)
        throw(ArgumentError("atol must be finite and nonnegative"))
    end

    if !result.optimal
        throw(ArgumentError("only an optimal result has flows to validate"))
    end

    if length(edges) != length(result.vector)
        throw(DimensionMismatch("one flow value is required per edge"))
    end

    # Set up one balance entry per node, using the same node order as the model's b vector -
    vertices = result.formulation.vertices
    number_of_nodes = length(vertices)
    number_of_edges = length(edges)
    row = Dict{Int64,Int}()
    for i in 1:number_of_nodes
        row[vertices[i]] = i
    end

    # Recompute balances from the edge endpoints rather than multiplying by A -
    # This independent calculation can reveal an incorrectly assembled incidence matrix.
    # Every edge subtracts its flow at the starting node and adds it at the ending node.
    net_inflow = zeros(Float64, number_of_nodes)
    costs = zeros(Float64, number_of_edges)
    bounds_ok = true # stays true only if every edge satisfies both bounds

    for j in 1:number_of_edges
        edge = edges[j]
        value = result.vector[j]
        source_row = row[edge.source]
        target_row = row[edge.target]
        net_inflow[source_row] -= value
        net_inflow[target_row] += value
        costs[j] = edge.cost

        if !(edge.lower - atol <= value <= edge.upper + atol)
            bounds_ok = false
        end
    end

    # Find the largest difference between a computed balance and the required balance -
    maximum_balance_residual = 0.0 # assignments; zero would mean exact agreement at every node
    for i in 1:number_of_nodes
        residual = abs(net_inflow[i] - result.formulation.b[i])
        maximum_balance_residual = max(maximum_balance_residual, residual)
    end
    balance_ok = maximum_balance_residual <= atol

    # Check the reported cost using the edge costs and returned flow values -
    # dot(...) multiplies corresponding entries and adds them: sum of cost[j] * flow[j].
    # rtol = 0.0 uses only our absolute tolerance, independent of the size of the total cost.
    recomputed_cost = dot(costs, result.vector)
    objective_ok = isapprox(recomputed_cost, result.cost; atol = atol, rtol = 0.0)

    # Report the individual checks as well as their combined result -
    # Feasibility and cost agreement do not prove optimality or whole-number assignments.
    return (
        valid = bounds_ok && balance_ok && objective_ok,
        bounds_ok = bounds_ok,
        balance_ok = balance_ok,
        objective_ok = objective_ok,
        maximum_balance_residual = maximum_balance_residual,
        recomputed_cost = recomputed_cost,
    )
end

# --- Reading the schedule --------------------------------------------------------

"""
    teaching_schedule(department::NamedTuple, network::NamedTuple,
        result::NamedTuple; atol::Real = 1e-8)

List the faculty–course assignments in an optimal result.

Returns a `DataFrame` with one row per faculty → course edge carrying flow
above `atol`, in course order: `course`, `title`, `name`, `score`, and `flow`.
Flows are reported as returned, without rounding; checking that they are whole
assignments is a separate step.
"""
function teaching_schedule(
    department::NamedTuple,
    network::NamedTuple,
    result::NamedTuple;
    atol::Real = 1e-8,
)

    # Require an optimal result before reading assignments -
    if !result.optimal
        throw(ArgumentError("an infeasible or unsolved model has no schedule"))
    end

    # Create an empty table with one column for each part of an assignment record -
    # The empty vectors specify the column types; selected assignments will become rows.
    schedule = DataFrame(
        course = String[],
        title = String[],
        name = String[],
        score = Int[],
        flow = Float64[],
    )

    # Visit courses in file order, checking every faculty member's flow to that course -
    # Only faculty → course edges represent the choices we want to list. Reading the
    # other network layers too would count the same assignment more than once.
    for course_row in eachrow(department.courses)
        for name in department.faculty.name
            faculty_id = network.faculty_node[name]
            course_id = network.course_node[course_row.course]
            pair = (faculty_id, course_id)

            value = 0.0
            if haskey(result.flow, pair)
                value = result.flow[pair]
            end

            # Ignore unused edges and values close to zero. Keep the reported flow as it is;
            # a separate test in the notebook checks that assignments are whole numbers.
            if value > atol
                score = _score(department, name, course_row.course)
                push!(schedule, (course_row.course, course_row.title, name, score, value))
            end
        end
    end

    return schedule
end

"""
    schedule_checks(department::NamedTuple, schedule::AbstractDataFrame; atol::Real = 1e-8)

Count each faculty member's assignments and each course's staffing in a
schedule and compare them with the department rules.

Returns a named tuple with two `DataFrame`s: `loads` (`name`, `required`,
`assigned`, `ok`) and `staffing` (`course`, `min_faculty`, `assigned`,
`max_faculty`, `ok`), plus `all_ok`. Assigned counts add the schedule's flow
values, so they are whole numbers only for a whole-number schedule. `atol` is
the absolute tolerance in assignments for load and staffing comparisons.
"""
function schedule_checks(
    department::NamedTuple,
    schedule::AbstractDataFrame;
    atol::Real = 1e-8,
)

    # Count the assigned flow for each faculty member and compare it with the required load -
    # Start each count at zero so a faculty member with no assignment rows is still checked.
    # Add flow values rather than counting rows, so fractional values cannot be hidden.
    loads = DataFrame(name = String[], required = Int[], assigned = Float64[], ok = Bool[])

    for faculty_row in eachrow(department.faculty)
        assigned = 0.0
        for assignment in eachrow(schedule)
            if assignment.name == faculty_row.name
                assigned += assignment.flow
            end
        end

        load_ok = abs(assigned - faculty_row.load) <= atol
        push!(loads, (faculty_row.name, faculty_row.load, assigned, load_ok))
    end

    # Count the assigned flow for each course and compare it with both staffing limits -
    # This loop visits all courses, including any course absent from the schedule table.
    staffing = DataFrame(
        course = String[],
        min_faculty = Int[],
        assigned = Float64[],
        max_faculty = Int[],
        ok = Bool[],
    )

    for course_row in eachrow(department.courses)
        assigned = 0.0
        for assignment in eachrow(schedule)
            if assignment.course == course_row.course
                assigned += assignment.flow
            end
        end

        # Allow only the small numerical margin given by atol on either side of the interval.
        staffing_ok = course_row.min_faculty - atol <= assigned <= course_row.max_faculty + atol
        push!(staffing, (course_row.course, course_row.min_faculty, assigned, course_row.max_faculty, staffing_ok))
    end

    # all(...) is true only when every row's check passed; both tables must pass -
    all_ok = all(loads.ok) && all(staffing.ok)
    return (loads = loads, staffing = staffing, all_ok = all_ok)
end

"""
    assignments_by_faculty(department::NamedTuple, schedule::AbstractDataFrame)

Summarize a schedule from `teaching_schedule(...)` by faculty member.

Returns a `DataFrame` with one row per faculty member in `Faculty.csv` order:
`name`, `load`, `courses` (the assigned course codes joined with commas, or
`"none"`), and `scores` (the matching survey scores, in the same order). This is
the teaching-assignment table a department would publish.
"""
function assignments_by_faculty(department::NamedTuple, schedule::AbstractDataFrame)

    # Create one summary row per faculty member, in the original faculty-table order -
    # The default text also covers a faculty member with no assignments, such as someone on leave.
    number_of_faculty = nrow(department.faculty)
    rows = DataFrame(
        name = department.faculty.name,
        load = department.faculty.load,
        courses = fill("none", number_of_faculty),
        scores = fill("", number_of_faculty),
    )

    # Gather the course codes and scores for one faculty member at a time -
    for i in 1:number_of_faculty
        name = rows.name[i]
        course_codes = String[]
        score_text = String[]

        for assignment in eachrow(schedule)
            if assignment.name == name
                push!(course_codes, assignment.course)
                push!(score_text, string(assignment.score)) # convert the score to text for display
            end
        end

        # Appending to both lists together keeps each course aligned with its score.
        # join(...) turns each list into one comma-separated string for the table.
        if !isempty(course_codes)
            rows.courses[i] = join(course_codes, ", ")
            rows.scores[i] = join(score_text, ", ")
        end
    end

    return rows
end
