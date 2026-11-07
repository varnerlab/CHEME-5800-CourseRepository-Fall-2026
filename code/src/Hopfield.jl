# ------------------------------------------------------------------------------------------------ #
# Hopfield.jl
#
# Hopfield networks: recall a stored memory from a noisy or partial starting state. These functions
# come from earlier offerings of the course; no notebook in this course calls them.
#
# A classical Hopfield network stores memories, vectors of -1 and 1 spins, in a weight matrix W.
# Starting from a state s, it sets one spin at a time to the sign of its local field, which never
# raises the energy for the weights that build(...) makes, until the state stops changing. A modern
# Hopfield network stores the memories as the columns of a matrix X̂ and moves a continuous state
# toward a softmax-weighted average of the memories.
#
# Public functions:
#   recover(model::MyClassicalHopfieldNetworkModel, sₒ, trueenergyvalue; ...)
#                                  runs one-spin updates from sₒ and records each state and energy
#   recover(model::MyModernHopfieldNetworkModel, sₒ; ...)
#                                  runs softmax updates from sₒ and records each state and probability
#
# Private functions:
#   _energy(s, W, b)               the energy E(s) = −(1/2)⋅Σᵢ Σⱼ Wᵢⱼ⋅sᵢ⋅sⱼ − bᵀs of a state
#   _find_exact_memory_match(s, memories)
#                                  the index of the first stored memory equal to s, or nothing
#
# Random numbers: the classical recover(...) picks the spin to update with rand(1:N), one draw per
# iteration, from Julia's default random number generator. The modern recover(...) draws none.
# ------------------------------------------------------------------------------------------------ #

"""
    _energy(s::Array{<:Number,1}, W::Array{<:Number,2}, b::Array{<:Number,1}) -> Float32

Compute the energy of the state `s` of a classical Hopfield network:

`E(s) = −(1/2)⋅Σᵢ Σⱼ Wᵢⱼ⋅sᵢ⋅sⱼ − bᵀs`,

with both sums over `i, j = 1, 2, …, N`. With the weights and the zero bias that `build(...)`
makes, each one-spin update in `recover(...)` lowers this energy or leaves it unchanged.

### Arguments
- `s::Array{<:Number,1}`: the state, a vector of `N` spins, each -1 or 1. `Array{<:Number,1}` means
  a vector whose entries are any kind of number.
- `W::Array{<:Number,2}`: the `N × N` weight matrix.
- `b::Array{<:Number,1}`: the bias vector of length `N`.

### Returns
- `Float32`: the energy `E(s)`, converted to a 32-bit floating point number.
"""
function _energy(s::Array{<: Number,1}, W::Array{<:Number,2}, b::Array{<:Number,1})::Float32

    # initialize -
    tmp_energy_state = 0.0; # the double sum Σᵢ Σⱼ Wᵢⱼ⋅sᵢ⋅sⱼ, built up in the loop
    number_of_states = length(s); # N, the number of spins in the state

    # main loop: compute the bias term, then add up every term of the double sum -
    tmp = transpose(b)*s; # the bias term bᵀs
    for i ∈ 1:number_of_states
        for j ∈ 1:number_of_states
            tmp_energy_state += W[i,j]*s[i]*s[j]; # add one term of the double sum (x += y means x = x + y)
        end
    end
    energy_state = -(1/2)*tmp_energy_state - tmp; # E(s) = −(1/2)⋅(double sum) − bᵀs

    # return the energy; the ::Float32 in the first line of the function converts it to a 32-bit number -
    return energy_state;
end

"""
    _find_exact_memory_match(s::Array{Int32,1}, memories::Array{<:Number,2}) -> Union{Nothing,Int64}

Find the first stored memory that equals the state `s` in every entry.

We compare `s` with each column of `memories` in turn, using the Hamming distance: the number of
entries in which two vectors differ. A distance of 0 means the two vectors are equal.

### Arguments
- `s::Array{Int32,1}`: the state, a vector of `N` spins stored as 32-bit integers.
- `memories::Array{<:Number,2}`: the `N × K` matrix of stored memories, one memory per column.

### Returns
- `Int64`: the index `k` of the first column that equals `s`, or
- `nothing`, Julia's value for "no result", when no column equals `s`. The return type
  `Union{Nothing,Int64}` means the result is either `nothing` or an `Int64`.
"""
function _find_exact_memory_match(s::Array{Int32,1}, memories::Array{<:Number,2})::Union{Nothing,Int64}

    # loop over stored memories and return the first exact match -
    number_of_memories = size(memories, 2); # the number of columns, one per memory
    for k ∈ 1:number_of_memories
        if (hamming(s, @view(memories[:,k])) == 0) # hamming(...) counts the entries that differ; @view(...) reads column k without copying it
            return Int64(k); # memory k matches: stop and return its index
        end
    end

    # no exact match: return nothing -
    return nothing;
end

# -- PUBLIC METHODS BELOW HERE -------------------------------------------------------------------------------------------------------- #

"""
    recover(model::MyClassicalHopfieldNetworkModel, sₒ::Array{Int32,1}, trueenergyvalue::Float32;
        maxiterations::Int = 1000, patience::Union{Int,Nothing} = nothing,
        miniterations_before_convergence::Union{Int,Nothing} = nothing) -> Tuple{Dict{Int64, Array{Int32,1}}, Dict{Int64, Float32}}

Recover a stored memory from the starting state `sₒ` with asynchronous (one spin at a time) updates
of a classical Hopfield network, and record the state and the energy after every update.

Each iteration updates one spin:
1. Pick a spin `j` uniformly at random from `1, 2, …, N`.
2. Compute its local field, `h = Σₖ W[j,k]⋅s[k] − b[j]`.
3. If `h > 0`, set `s[j] = 1`. If `h < 0`, set `s[j] = -1`. If `h = 0`, keep `s[j]`.
4. Record the new state and its energy `E(s)` (see `_energy`).

Before the first iteration, the function stops at once and returns only the starting frame if `sₒ`
equals a stored memory, or if its energy is already at or below `trueenergyvalue`. After each
iteration, it stops when any of these holds:
- the state equals a stored memory (checked when the model has memories, as `build(...)` gives it);
- the last `patience` recorded states are identical, at least `miniterations_before_convergence`
  iterations have run, and every spin has been picked at least once since the state last changed;
- the energy is at or below `trueenergyvalue`;
- `maxiterations` iterations have run.

Each stop prints a message with `@info`, or a warning with `@warn` for the iteration limit. More
than one condition can hold in the same iteration, and then each prints its message.

Random draws: one `rand(1:N)` per iteration, from Julia's default random number generator, so
`Random.seed!(seed)` before the call repeats the run.

### Arguments
- `model::MyClassicalHopfieldNetworkModel`: the network, built with `build(...)`. We use its
  weight matrix `W` (`N × N`), its bias vector `b` (length `N`), and, when present, its stored
  memories `memories` (`N × K`, one memory per column).
- `sₒ::Array{Int32,1}`: the starting state, a vector of `N` spins, each -1 or 1. It is not changed.
- `trueenergyvalue::Float32`: the energy threshold: we stop as soon as the energy is at or below it.
  The field `model.energy[k]` holds the energy of stored memory `k`.
- `maxiterations::Int = 1000`: the largest number of one-spin updates.
- `patience::Union{Int,Nothing} = nothing`: the number of recorded states that must be identical
  to declare convergence. With `nothing`, we use `max(5, round(0.1⋅N))`, where `N` is the number of
  spins.
- `miniterations_before_convergence::Union{Int,Nothing} = nothing`: the fewest iterations before
  we check for convergence. With `nothing`, we use `patience`, and a smaller value is raised to
  `patience`.

### Returns
A tuple `(frames, energydictionary)` of two dictionaries, both keyed by the iteration number, with
key `0` for the starting state:
- `frames::Dict{Int64, Array{Int32,1}}`: the state after each iteration.
- `energydictionary::Dict{Int64, Float32}`: the energy of the state after each iteration.
"""
function recover(model::MyClassicalHopfieldNetworkModel, sₒ::Array{Int32,1}, trueenergyvalue::Float32;
    maxiterations::Int = 1000, patience::Union{Int,Nothing} = nothing,
    miniterations_before_convergence::Union{Int,Nothing} = nothing)::Tuple{Dict{Int64, Array{Int32,1}}, Dict{Int64, Float32}}

    # initialize. `c ? a : b` means: if c is true, use a; otherwise, use b. isnothing(x) is true when x is nothing -
    W = model.W; # get the weights, the N × N matrix W
    b = model.b; # get the biases, the vector b of length N
    number_of_pixels = length(sₒ); # N, the number of spins (one per pixel of an image)
    patience_val = isnothing(patience) ? max(5, Int(round(0.1 * number_of_pixels))) : patience; # if patience is nothing, use max(5, round(0.1⋅N)); otherwise, use patience
    min_iterations = max(isnothing(miniterations_before_convergence) ? patience_val : miniterations_before_convergence, patience_val); # use patience_val when miniterations_before_convergence is nothing; then raise a smaller value to patience_val
    S = CircularBuffer{Array{Int32,1}}(patience_val); # a buffer of the last patience_val states: when it is full, pushing a new state drops the oldest (from DataStructures)

    # initialize the records -
    frames = Dict{Int64, Array{Int32,1}}(); # frames[k]: the state after iteration k
    energydictionary = Dict{Int64, Float32}(); # energydictionary[k]: the energy after iteration k
    has_converged = false; # convergence flag: true once any stopping rule fires
    visited_since_last_change = falses(number_of_pixels); # entry j is true if spin j was picked since the state last changed; falses(N) makes N false values

    # setup -
    frames[0] = copy(sₒ); # copy the initial state into frame 0
    initial_energy = _energy(sₒ,W, b); # E(sₒ), the energy of the starting state
    energydictionary[0] = initial_energy; # initial energy
    s = copy(sₒ); # the state we update: a copy, so sₒ is not changed

    # early stop: the input is already an exact stored memory. isdefined(model, :memories) is true
    # when the field memories has been set, and !isnothing(x) means "x is not nothing" -
    if isdefined(model, :memories)
        matched_memory_index = _find_exact_memory_match(s, model.memories); # the index of the matching memory, or nothing
        if !isnothing(matched_memory_index)
            @info "Initial state exactly matches stored memory index = $(matched_memory_index). Stopping." # print a message
            return frames, energydictionary # stop, and return the starting frame only
        end
    end

    # early stop: the input already satisfies the energy threshold -
    if (initial_energy ≤ trueenergyvalue)
        @info "Initial state energy is already below threshold. Stopping."
        return frames, energydictionary # stop, and return the starting frame only
    end

    # main loop: one spin update per pass, until a stopping rule fires -
    iteration_counter = 1; # the number of the current iteration
    while (has_converged == false)

        # steps 1 and 2: pick a random spin j, and compute its local field h -
        j = rand(1:number_of_pixels); # select a random pixel: an integer from 1 to N, from the default random number generator
        old_spin = s[j]; # the spin before the update
        h = dot(@view(W[j,:]), s) - b[j]; # local field at node j: h = Σₖ W[j,k]⋅s[k] − b[j]; @view(...) reads row j of W without copying it

        # step 3: set the spin to the sign of h.
        # Edge case: if h == 0, keep current spin to avoid injecting randomness -
        if iszero(h)
            nothing; # do nothing: keep s[j]
        else
            s[j] = h > 0 ? Int32(1) : Int32(-1); # map sign to ±1 spins: if h > 0, use 1; otherwise, use -1 (Int32(...) makes a 32-bit integer)
        end
        did_state_change = (s[j] != old_spin); # true if the update flipped spin j

        # If the state changed, we start a new plateau window: forget which spins were picked -
        if did_state_change
            fill!(visited_since_last_change, false); # set every entry to false (a function name ending in ! changes its argument)
        end
        visited_since_last_change[j] = true; # spin j has been picked since the last change

        # step 4: record the energy and the state of this iteration -
        energydictionary[iteration_counter] = _energy(s, W, b);
        state_snapshot = copy(s); # single snapshot reused for storage and convergence checks
        frames[iteration_counter] = state_snapshot;

        # stop as soon as we recover an exact stored memory -
        if isdefined(model, :memories)
            matched_memory_index = _find_exact_memory_match(state_snapshot, model.memories); # the index of the matching memory, or nothing
            if !isnothing(matched_memory_index)
                has_converged = true; # stop after this iteration
                @info "Recovered exact stored memory index = $(matched_memory_index). Stopping."
            end
        end

        # check for convergence: once the buffer is full and enough iterations have run, we compare
        # every buffered state with the oldest one -
        push!(S, state_snapshot); # push the current state to the buffer; when the buffer is full, the oldest state drops out
        if (length(S) == patience_val) && (iteration_counter >= min_iterations) # && means "and"
            all_equal = true; # true until we find a buffered state that differs from the oldest one
            first_state = S[1]; # look at the oldest state in the buffer
            for state ∈ S
                if (hamming(first_state, state) != 0) # hamming(...) counts the entries that differ
                    all_equal = false;
                    break; # leave the for loop: one difference is enough
                end
            end
            # Convergence requires:
            # 1) no changes over the buffered window, and
            # 2) every neuron was visited at least once since the last change.
            # all(v) is true when every entry of v is true -
            if (all_equal == true) && all(visited_since_last_change)
                has_converged = true; # we have converged
                @info "Convergence detected: no state changes over the last $patience_val iterations and all neurons visited since last change. Stopping."
            end
        end

        # is the energy at or below the threshold? -
        current_energy = energydictionary[iteration_counter]; # the energy recorded in step 4
        if (current_energy ≤ trueenergyvalue)
            has_converged = true; # stop
            @info "Energy value lower than true. Stopping"
        end

        # update counter, and check max iterations -
        iteration_counter += 1; # x += y means x = x + y
        if (iteration_counter > maxiterations && has_converged == false)
            has_converged = true; # we have reached the maximum number of iterations
            @warn "Maximum iterations reached without convergence." # print a warning
        end


    end

    # return the frames and the energies as a tuple. A function returns the value of its last line -
    frames, energydictionary
end



"""
    recover(model::MyModernHopfieldNetworkModel, sₒ::Array{T,1};
        maxiterations::Int64 = 1000, ϵₚ::Float64 = 1e-10, ϵₛ::Float64 = 1e-10) where T <: Number -> Tuple

Recover a stored memory from the starting state `sₒ` with the updates of a modern Hopfield
network, and record the state and the probabilities after every update.

The memories are the columns of the normalized memory matrix `X̂ = model.X̂`. Each iteration takes
two steps:
1. Compute the probability of each memory, `p = softmax(β⋅X̂ᵀs)`, where
   `softmax(z)ᵢ = exp(zᵢ) / Σₖ exp(zₖ)` and `β = model.β` is the inverse temperature. A memory with
   a larger inner product with the state `s` gets a larger probability. A larger `β` puts more of
   the probability on the memory with the largest inner product.
2. Update the state to the probability-weighted average of the memories, `s ← X̂⋅p`.

From the second iteration on, we measure how much the probabilities and the state changed since
the previous iteration: `Δₚ = (1/2)⋅‖pₖ − pₖ₋₁‖₁`, half the sum of the absolute changes, and
`Δₛ = (1/2)⋅‖sₖ − sₖ₋₁‖₂`, half the Euclidean length of the change. We stop when both `Δₚ ≤ ϵₚ`
and `Δₛ ≤ ϵₛ`, or when `maxiterations` iterations have run. The iteration limit is checked first:
the last allowed iteration stops with a warning, even if it also meets the tolerances.

There are no random draws.

### Arguments
- `model::MyModernHopfieldNetworkModel`: the network, built with `build(...)`. We use the
  normalized memory matrix `model.X̂` (`N × K`, one memory per column) and the inverse temperature
  `model.β`. The matrix `model.X` is not used.
- `sₒ::Array{T,1}`: the starting state, a vector of `N` numbers. `where T <: Number` means that
  `T` can be any number type. The starting state is not changed.
- `maxiterations::Int64 = 1000`: the largest number of iterations.
- `ϵₚ::Float64 = 1e-10`: the tolerance on the change in the probabilities, `Δₚ`.
- `ϵₛ::Float64 = 1e-10`: the tolerance on the change in the state, `Δₛ`.

### Returns
A tuple `(s, frames, probability)`:
- `s`: the final state, a vector of length `N`.
- `frames::Dict{Int64, Array{Float32,1}}`: the state after each iteration, keyed by the iteration
  number, with key `0` for the starting state. The states are stored as 32-bit numbers.
- `probability::Dict{Int64, Array{Float64,1}}`: the probability vector `p` of each iteration, with
  key `0` for the probabilities computed from the starting state.
"""
function recover(model::MyModernHopfieldNetworkModel, sₒ::Array{T,1};
    maxiterations::Int64 = 1000, ϵₚ::Float64 = 1e-10, ϵₛ::Float64 = 1e-10) where T <: Number

    # initialize -
    X = model.X̂; # the normalized data matrix X̂ from the model. This holds the memories on the columns
    β = model.β; # beta parameter (inverse temperature)

    frames = Dict{Int64, Array{Float32,1}}(); # frames[k]: the state after iteration k, stored as 32-bit numbers
    probability = Dict{Int64, Array{Float64,1}}(); # probability[k]: the probabilities of iteration k
    frames[0] = copy(sₒ); # copy the initial state into frame 0
    probability[0] = softmax(β*transpose(X)*sₒ); # initial probability, softmax(β⋅X̂ᵀsₒ); softmax(...) comes from the NNlib package
    should_stop_iteration = false; # flag to stop the iteration
    iteration_counter = 1; # iteration counter

    # loop -
    s = copy(sₒ); # the state we update: a copy, so sₒ is not changed
    Δₚ = Inf; # the change in the probabilities; Inf (infinity) until we can compute it in iteration 2
    Δₛ = Inf; # the change in the state; Inf until iteration 2
    while (should_stop_iteration == false)

        p = softmax(β*transpose(X)*s); # step 1: compute the probabilities, softmax(β⋅X̂ᵀs)
        s = X*p; # step 2: update the state, the probability-weighted average of the memories

        frames[iteration_counter] = copy(s); # save a copy of the state in the frames dictionary
        probability[iteration_counter] = p; # save the probabilities in the probability dictionary

        # first: compute the change in the probabilities, Δₚ = (1/2)⋅‖pₖ − pₖ₋₁‖₁ -
        if (iteration_counter > 1)
            Δₚ = (1/2)*norm(probability[iteration_counter] - probability[iteration_counter-1], 1); # L1 change: norm(v, 1) is the sum of the absolute values of v
        end

        # next: compute the change in the state, Δₛ = (1/2)⋅‖sₖ − sₖ₋₁‖₂, from the 32-bit copies in frames -
        if (iteration_counter > 1)
            Δₛ = (1/2)*norm(frames[iteration_counter] - frames[iteration_counter-1], 2); # L2 change: norm(v, 2) is the Euclidean length of v
        end

        # next: check for convergence. If we are out of iterations or both changes are small, we stop -
        if (iteration_counter >= maxiterations)
            should_stop_iteration = true;
            @warn "Maximum iterations ($maxiterations) reached before convergence (Δ = $Δₚ, ϵ = $ϵₚ)." # print a warning with the last Δₚ
        elseif (Δₚ ≤ ϵₚ && Δₛ ≤ ϵₛ) # && means "and"
            should_stop_iteration = true;
        else
            iteration_counter += 1; # increment the iteration counter, we are not done yet. Keep going.
        end
    end

    # return the final state, the state of every iteration, and the probabilities of every iteration -
    return s,frames,probability
end
# -- HOPFIELD METHODS ABOVE HERE -------------------------------------------------------------------------------------------------------- #
