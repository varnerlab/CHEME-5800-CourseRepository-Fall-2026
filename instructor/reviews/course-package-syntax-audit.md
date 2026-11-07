# Course package syntax audit

Students reported that the code in `code/src` is hard to follow. On November 7, 2026, we added comments and docstrings to all 23 files and changed no code. This audit lists the constructs that are still hard for beginners. Each row gives a plain rewrite and says whether the rewrite could change results. No rewrite has been applied.

Line numbers refer to the commented files of November 7, 2026. They may drift after later edits, so search for the quoted construct.

## Summary

| File | Constructs | Verdict |
|---|---|---|
| `ShortestPathAlgorithms.jl` | 23 | rewrite recommended |
| `Factory.jl` | 21 | rewrite recommended |
| `MDP.jl` | 20 | rewrite recommended |
| `Graphs.jl` | 19 | rewrite recommended |
| `Bandit.jl` | 18 | rewrite recommended |
| `Compute.jl` | 18 | rewrite recommended |
| `Files.jl` | 18 | rewrite recommended |
| `Binary.jl` | 16 | rewrite recommended |
| `Eigen.jl` | 16 | rewrite recommended |
| `GraphRepresentation.jl` | 16 | rewrite recommended |
| `Hopfield.jl` | 16 | rewrite recommended |
| `FlowValidation.jl` | 15 | rewrite recommended |
| `Recursion.jl` | 15 | rewrite recommended |
| `FluxBalance.jl` | 14 | rewrite recommended |
| `Solvers.jl` | 14 | rewrite recommended |
| `LinearPrograms.jl` | 12 | rewrite recommended |
| `Types.jl` | 12 | comments enough |
| `Indifference.jl` | 11 | rewrite recommended |
| `Online.jl` | 8 | rewrite recommended |
| `StacksQueues.jl` | 6 | rewrite recommended |
| `QLearning.jl` | 5 | comments enough |
| `VLDataScienceMachineLearningPackage.jl` | 4 | comments enough |
| `TextRepresentation.jl` | 2 | rewrite recommended |
| **Total** | **319** | |

The most common constructs are one-line checks and exits (`cond || throw(...)`, `&& return`, `&& continue`), ternaries, anonymous functions piped with `|>`, comprehension-heavy one-liners, `do` blocks, and `while true` loops that end only at a `return`. Most of them become explicit if-blocks and loops with identical results.

## Rewrites that could change results

Rows whose last column starts with "Yes" could change results. Skip them, or re-run and re-check the notebooks that depend on them. The main ones are:

- `MDP.jl`: replacing `Categorical` with `rand(1:4)` changes the random draws, so the L11c rollout numbers would change.
- `MDP.jl`: replacing `sum([...])` in `Q` with a loop can change the last bits of a sum. With exactly tied action values, the policy could then choose a different action.
- `FluxBalance.jl`: the plain form of `maximum(abs, S * flux; init = 0.0)` must still catch `NaN`, or a `NaN` flux would pass the balance check.
- `Graphs.jl`: replacing `record...` in `weighted_edges` with `record[1]`, `record[2]`, `record[3]` would accept a record with four entries.
- `ShortestPathAlgorithms.jl`: narrowing `AbstractVector{<:Integer}` in `path_cost` would reject a range or a `Vector{Int32}`.
- `Factory.jl`: replacing the `undef` placeholders with zeros changes the starting contents of those arrays.

## How to apply the rewrites

- Rewrite one file at a time, and keep every public name and signature, because the notebooks call them.
- Before and after each file, run `julia --startup-file=no --project=. instructor/validation/week-NN/runtests.jl` for weeks 1 to 12, and compare the results. On November 7, 2026, weeks 8 and 11 already failed for reasons unrelated to the package: commit 9bfabcb changed δ in the L8c example, and commit df9c57f changed the L11d lab.
- For each changed function, also compare its outputs on the docstring examples before and after the rewrite.

## Syntax audit: code/src/Bandit.jl

Line numbers refer to the commented file. Students see this file through the L10c UCB1 example and the L10d lab, which call `solve(...)` for explore-first, epsilon-greedy, and UCB1. The consumer-choice `_solve(...)` and `regret(...)` are not called by any notebook.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 52 | `_null(action::Int64)::Int64 = return 0;` | The short form `f(x) = ...` does not look like a function definition, and the `return` inside it is redundant. | `function _null(action::Int64)::Int64` / `return 0;` / `end` | No. |
| 74, 77 | `K ≥ 1 \|\| throw(ArgumentError("K must be at least 1"))` (and the `T ≥ K` line) | Short-circuit `\|\|` used as control flow; the instructor has objected to this form. | `if (K < 1)` / `throw(ArgumentError("K must be at least 1"));` / `end`, and the same for `T < K`. | The function would return `nothing` instead of `true`; every caller ignores the value. Error types and messages are unchanged. |
| 97-98 | `_bandit_output(...) =` / `return_history ? (actions = actions, rewards = rewards) : rewards` | A one-line function split over two lines, with a ternary as its body. | `function _bandit_output(rewards, actions, return_history::Bool)` / `if (return_history == true)` / `return (actions = actions, rewards = rewards);` / `end` / `return rewards;` / `end` | No. |
| 149 | `Nₐ = clamp(round(Int, (T/K)^(2/3)*cbrt(log(T))), 1, fld(T, K));` | Five nested calls in one line; `clamp`, `fld`, and `cbrt` are unfamiliar. | `N_raw = (T/K)^(2/3)*cbrt(log(T));` / `Nₐ = round(Int, N_raw);` / `N_max = fld(T, K);` / `if (Nₐ < 1) Nₐ = 1; end` / `if (Nₐ > N_max) Nₐ = N_max; end` | No. `T ≥ K` makes `N_max ≥ 1`, so the if-blocks match `clamp`. |
| 154, 169 | `for _ ∈ 1:Nₐ` | An underscore as a loop variable looks like a typo. | `for k ∈ 1:Nₐ` | No. |
| 157 (and many lines) | `totals[a] += rewards[counter, a]` | Compound assignment `+=`. The comments now explain it. | `totals[a] = totals[a] + rewards[counter, a]` | No. |
| 165, 248, 325 | `μ = totals ./ pulls;` and `aₜ = argmax(totals ./ pulls);` | The broadcasting dot, here inside a function call. | `μ = zeros(K);` / `for a ∈ 1:K μ[a] = totals[a]/pulls[a]; end` / `aₜ = argmax(μ);` | No. Element-by-element division gives the same numbers. |
| 312 | `for a = 1:K` | The other loops in the file use `∈`, so the two spellings look like different constructs. | `for a ∈ 1:K` | No. |
| 416-419, 442-445 | `aₜ = digits(i, base=2, pad=K);` followed by an `if (i == N)` patch | `digits` is unfamiliar, and the arm-to-bundle mapping is written twice. The patch makes arms N−1 and N choose the same bundle, so the empty bundle is never tried. | Move the mapping into one documented helper, `_bundle(i::Int, K::Int, N::Int)`, that holds the same if-block, and call it in both places. | No, if the helper keeps the patch. Mapping every arm `i` to `digits(i - 1, ...)` would remove the duplicate, but it changes which bundles are played and the results. |
| 420, 448 | `r,n,p,γ = world(startdayindex, aₜ, context);` | Unpacking a tuple without parentheses, into one-letter names (`p` is reused for the random number at line 433). | `(reward, shares, prices, preferences) = world(startdayindex, aₜ, context);` | No. |
| 424 | `S[1, :] = n;` | Assigning a whole vector into one row of a matrix. | `for k ∈ 1:K S[1, k] = n[k]; end` | Values: no. A vector of the wrong length would give a `BoundsError` instead of a `DimensionMismatch`. |
| 431 | `ϵₜ = (1.0/(t^(1/3)))*(log(K*t))^(1/3);` | The same quantity as `cbrt(log(K*t)/t)` written a second way. The other epsilon-greedy method caps it at 1, and this one does not. | `ϵₜ = cbrt(log(K*t)/t);` | Possibly. The last digits of `ϵₜ` can differ, so in a rare round `u ≤ ϵₜ` could flip. That would change whether `rand(1:N)` is drawn, and so the order of the random draws after that round. |
| 435-436 | `aₜ = nothing;` / `î = nothing;` | A placeholder of a different type, overwritten a few lines later. | `î = 0;` and delete the `aₜ = nothing` line. | No. Both variables are always set before they are used. |
| 451 | `μ[î]+=(1/t)*(rₜ - μ[î]);` | Compound assignment without spaces, and an update rule that hides the step size `1/t`. | `step = 1/t;` / `μ[î] = μ[î] + step*(rₜ - μ[î]);` | No. |
| 465 | `return R, μ, S, P, G;` | Five arrays in an unnamed tuple, so the caller must memorize the order. | `return (R = R, μ = μ, S = S, P = P, G = G);` | Yes: the return type becomes a `NamedTuple`. Positional unpacking `R, μ, S, P, G = solve(...)` still works. |
| 600 | `regret = zeros(Float64, T);` | A local variable with the same name as the function it is in. | `regret_values = zeros(Float64, T);` (and rename its two uses) | No. |
| 608 | `μ[a] = findall(x -> x != 0.0, rewards[:, a]) \|> i-> mean(rewards[i, a]);` | Two anonymous functions joined by a pipe; the instructor has objected to closures and to `\|>` chains. | `total = 0.0;` / `number_nonzero = 0;` / `for t ∈ 1:T` / `if (rewards[t, a] != 0.0)` / `total = total + rewards[t, a];` / `number_nonzero = number_nonzero + 1;` / `end` / `end` / `μ[a] = total/number_nonzero;` | Possibly in the last digits: `mean` adds the entries in a different order than the loop does. An empty column still gives `NaN`, because `0.0/0` is `NaN`. |
| 613-620 | the nested loop `for t ∈ 1:T` / `for j = 1:t` that recomputes `Σⱼ μ[aⱼ]` | The inner loop restarts from round 1 for every `t`, which hides a running sum, and the cost grows like `T²`. | One loop: `running_sum = 0.0;` / `for t ∈ 1:T` / `aₜ = argmax(rewards[t, :]);` / `running_sum = running_sum + μ[aₜ];` / `regret[t] = μₒ*t - running_sum;` / `end` | No. The terms are added in the same order, so the values are identical. It is also much faster for large `T`. |

Notes (not syntax): `regret(...)` infers the pulled arm from `argmax(rewards[j, :])`, so a pull that earned 0 counts as a pull of arm 1. Passing the `actions` vector from `solve(...; return_history = true)` would fix this, but it changes the function's arguments and its results.

Verdict: rewrite recommended. The `||` checks at lines 74 and 77, the ternary at line 98, and the closure-and-pipe line in `regret(...)` at 608 are all forms the instructor has objected to.

## Syntax audit: code/src/Binary.jl

Line numbers refer to the commented file. Students see this file through the week-09 notebooks, which call `learn(...)` (Perceptron, with and without `pocket = true`), `classify(...)`, and `confusion(...)`. No notebook uses the logistic regression methods.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 58 | `function ∇f(f,x,y,T,λ,θ,h)` | `∇f` reads as math, not as a function name. The seven untyped one-letter arguments include a function `f` passed in as a value. | `function _finite_difference_gradient(loss::Function, x::Array{<:Number,1}, y::Number, T::Number, λ::Number, θ::Array{<:Number,1}, h::Number)::Array{Float64,1}`, and rename the one call at line 260. | No for the rename. The added types would reject a call with, for example, a matrix `θ`; the only caller passes vectors. |
| 61 | `diff = zeros(size(θ))` | A local variable with the same name as Julia's `diff` function. | `gradient = zeros(length(θ))` | No for a vector `θ`. |
| 64, 150, 254 | `for i ∈ eachindex(θ)` / `for i ∈ eachindex(labels)` | `eachindex` is unfamiliar. The comments now explain it. | `for i ∈ 1:length(θ)` | No for ordinary arrays. |
| 94 | `_count_mistakes(...) = count(labels .* (features*β) .≤ 0);` | A one-line function with two broadcast operators and `count` over a vector of true/false values. | `function _count_mistakes(features, labels, β)::Int` / `scores = features*β;` / `number_of_mistakes = 0;` / `for i ∈ eachindex(labels)` / `if (labels[i]*scores[i] ≤ 0)` / `number_of_mistakes = number_of_mistakes + 1;` / `end` / `end` / `return number_of_mistakes;` / `end` | No. |
| 80, 94, 97 and the signatures | `Array{<:Number,2}`, `AbstractVector{<:Number}` | The `<:` inside a type parameter. The comments now explain it. | Comments are enough. `Array{Float64,2}` would be simpler to read, but it would reject integer data. | Yes, if narrowed to `Float64`. |
| 156 | `if (y*sum(β̂.*x)) ≤ 0` | A broadcast inside `sum` stands for a dot product. The parentheses look as if they close the `if` condition early. | `score = dot(x, β̂);` / `if (y*score ≤ 0)` | Possibly. `dot` and `sum` can add the products in different orders, so a score at or very near 0 could change sign. That would change which updates happen and the learned parameters. A plain `for` loop has the same caveat. |
| 157 | `β̂ = β̂ .+ y*x;` | The broadcasting dot, and a new vector made on every update. | `for k ∈ eachindex(β̂)` / `β̂[k] = β̂[k] + y*x[k];` / `end` | No change in values. The in-place loop is safe only because `β_pocket` is always stored with `copy(...)`; keep those copies. |
| 158 and others | `error_counter+=1` | Compound assignment without spaces. | `error_counter = error_counter + 1;` | No. |
| 191 | `algorithm.β = (pocket == true) ? β_pocket : β̂;` | A ternary. | `if (pocket == true)` / `algorithm.β = β_pocket;` / `else` / `algorithm.β = β̂;` / `end` | No. |
| 247 | `error = nothing;` | A local variable with the same name as Julia's `error` function. It starts as `nothing` and later holds a number. | `gradient_norm = Inf;` (and rename its two uses) | Only when `maxiter < 1`: the verbose message would print `Inf` instead of `nothing`. |
| 260, 264 | `∇L = ∇L .+ ∇f(...)`, `βᵢ = βᵢ .- α*∇L` | Broadcasting dots. | `for k ∈ eachindex(∇L) ∇L[k] = ∇L[k] + g[k]; end`, with `g = ∇f(...)`, and the same loop for the step. | No. |
| 308 | `return sign.(features*algorithm.β);` | A broadcast of `sign`. Julia's `sign(0)` is 0, while the lecture's sign function gives 1, so every notebook adds a fix-up line. | `scores = features*algorithm.β;` / `labels = zeros(length(scores));` / `for i ∈ eachindex(scores)` / `if (scores[i] > 0) labels[i] = 1.0; elseif (scores[i] < 0) labels[i] = -1.0; end` / `end` / `return labels;` | No if a zero score still gives 0. Giving 1 at 0, as the lecture does, would change the output, and the notebooks' `ŷ[ŷ .== 0] .= 1` lines would then do nothing. |
| 396, 401 | `kwargs...` in the signature, and `_learn(...; maxiter = maxiter, verbose = verbose, kwargs...)` | Keyword splatting hides which options exist: `pocket` appears nowhere in the signature of `learn`. | Give `learn` an explicit `pocket::Bool = false` keyword. Pass it on only when `algorithm` is a `MyPerceptronClassificationModel`, for example with two `learn` methods, one per model type. | Only the error for a wrong keyword changes: it would come from `learn` instead of `_learn`. |
| 449-452 | `classify(test::Array{<:Number,1}, ...; reverse::Bool = false)` calling `_classify(test, algorithm, reverse = reverse)` | No `_classify(...)` method accepts a vector or a `reverse` keyword, so every call fails with a `MethodError`. The method is left over from a removed nearest-neighbor classifier. | Delete this method and its docstring. To classify one example, pass a one-row matrix to the matrix method. | Calls that fail now would still fail, with a different `MethodError` message. |
| 493-526 | four copies of `counter = 0;` / `for i ∈ 1:number_of_test_examples` / `if (...)` | Long and repetitive, but plain. | Comments are enough. Optionally use one loop with an `if`/`elseif` chain that adds 1 to the right matrix entry. | No. |
| 529 | `confusion_matrix` as the last line | An implicit return: the value of the last line is returned without `return`. | `return confusion_matrix;` | No. |

Verdict: rewrite recommended. The ternary at 191, the broadcast one-liner `_count_mistakes` at 94, the hidden `pocket` keyword behind `kwargs...`, and the dead vector `classify(...)` method are the main problems.

## Syntax audit: code/src/Compute.jl

Line numbers refer to the commented file.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 79 | `fields = split(s, delim) .\|> String;` | Broadcast pipe `.\|>`: a dot and a pipe together, to convert each `SubString` to `String`. | `pieces = split(s, delim); fields = Array{String,1}(); for piece ∈ pieces push!(fields, String(piece)); end` | No. |
| 96, 99 | `foreach(i->push!(tokenarray, tokens["<pad>"]), (N+1):pad);` | Anonymous function passed to `foreach`; its argument `i` is ignored; the empty-range case (no padding) is invisible. | `for i ∈ (N+1):pad push!(tokenarray, tokens["<pad>"]); end` (and `pushfirst!` for left padding). | No. |
| 149 | `testfirm="AAPL"` | The only untyped keyword in the signature; its type is a guess. | `testfirm::String = "AAPL"` | Type only: a non-`String` ticker (for example a `SubString`) would then give a `MethodError`. |
| 154, 214, 215 | `Array{Float64,2}(undef, ...)` (then `fill!` at 216-217) | `undef` arrays hold arbitrary values until filled; two lines do the work of one. | `return_matrix = zeros(number_of_trading_days-1, number_of_firms);` `counts = zeros(Int64, number_of_letters);` `P = zeros(number_of_letters, number_of_letters);` | No. |
| 157, 220, 295, 303 | `for i ∈ eachindex(firms)` | `eachindex` is one more name to learn for `1:length(firms)`. | `for i ∈ 1:length(firms)` | No, for the `Array` arguments these functions accept. |
| 160 | `firm_index = firms[i];` | The name says index, but the value is a ticker symbol. | `ticker = firms[i]; firm_data = dataset[ticker];` | No. |
| 167 | `return_matrix[j-1, i] = ...` | The matrix holds growth rates, not returns. | Rename `return_matrix` to `growth_matrix`. | No. |
| 217, 245 | `fill!(counts,0.0)` on an `Int64` array | Filling an integer array with a float works only because `0.0` converts exactly to `0`. | `fill!(counts, 0);` | No. |
| 225 | `wordsdictionary[startchar] \|> copy` | Pipe instead of a plain call. | `copy(wordsdictionary[startchar])` | No. |
| 225-228 | `while (isempty(set_of_words) == false) word = pop!(set_of_words);` on a copy | A destructive loop over a copy, where a plain `for` loop over the set does the same job. | `for word ∈ wordsdictionary[startchar] ... end` and delete the copy. | No. The visiting order differs, but the integer counts do not depend on order. Faster: no copy. |
| 232 | `next_char = word[2];` | String indexing counts bytes, not characters. It is right here because every first letter in the data is one byte. | `characters = collect(word); next_char = characters[2];` | Same result on the course data. A word with a multibyte first letter would no longer throw a `StringIndexError`. |
| 233-234 | `j = findfirst(x-> x == next_char, letters); counts[j] = counts[j] + 1;` | Anonymous predicate; a second character not in `letters` gives `j = nothing` and a cryptic `ArgumentError: invalid index: nothing` one line later. | `j = 0; for position ∈ 1:length(letters) if (letters[position] == next_char) j = position; break; end end; if (j == 0) throw(ArgumentError("the second character of $(word) is not in letters")); end` | Error message only. (Skipping such words instead, as the L11b student function does, would change behavior on other vocabularies, not on the course data.) |
| 235 | `N += 1;` | Compound assignment. | `N = N + 1;` | No. |
| 241 | `P[i,k] = counts[k]/N;` | When no word has a second letter, `N = 0` and the row silently becomes `NaN`. | Add a check before the loop: `if (N == 0) throw(ArgumentError("no word that starts with $(startchar) has a second letter")); end` | Yes: an error instead of a `NaN` row. Optional; the course data never has `N = 0`. |
| 293-297, 318 | `letterindexmap = Dict{Int64,Char}()` ... `letterindexmap[k]` | A dictionary from position to letter that copies `letters`; students look for a difference. | Delete the dictionary and use `letters[k]`. | No. |
| 316 | `for _ ∈ 2:length_of_sample_word` | The underscore loop variable is unfamiliar. | `for step ∈ 2:length_of_sample_word` | No. |
| 318 | `next_char = rand(d) \|> k-> letterindexmap[k];` | Pipe into an anonymous function. | `k = rand(d); next_char = letters[k];` | No. One draw per letter from the same global generator, so the draw order and the words are unchanged. |
| 324 | `wordvector \|> join` | Pipe instead of a plain call. | `join(wordvector)` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/Eigen.jl

Line numbers refer to the commented file. No course notebook calls `qriteration(...)`, so a rewrite is low priority.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 45 | `ɛ=T <: Union{Rational,Integer} ? 0 : eps(norm(A,Inf))` default argument | A ternary inside a default argument, a type test `T <: Union{...}`, and `where T`. The name `ɛ` is the Latin open e (U+025B), which looks like `ϵ` (U+03F5, used in `qriteration`) but is a different character. | Drop the optional argument and compute it in the body: `tolerance = 0.0; if (T <: Union{Rational,Integer}) tolerance = 0; else tolerance = eps(norm(A,Inf)); end` | No for current callers (`qriteration` never passes `ɛ`). It removes the option to pass a tolerance. |
| 48 | `nr, nc = size(A)` | Tuple destructuring. | `nr = size(A, 1); nc = size(A, 2);` | No. |
| 49 | `i = j = 1` | Chained assignment. | `i = 1;` and `j = 1;` | No. |
| 57-58 | `(m, mi) = findmax(abs.(A[i:nr,j]))` and `mi = mi+i - 1` | Broadcast `abs.`, a slice, `findmax` returning (value, position), and a position-to-row conversion. | `m = abs(A[i,j]); mi = i; for k = (i+1):nr; if (abs(A[k,j]) > m) m = abs(A[k,j]); mi = k; end; end` | Ties: no (both keep the first). NaN: `findmax` treats NaN as the largest, the loop skips it. |
| 63 | `A[i:nr,j] .= zero(T)` | Broadcast assignment into a slice. | `for k = i:nr; A[k,j] = zero(T); end` | No. |
| 65, 79, 87, 93, 94 | `j += 1`, `A[i,k] /= d`, `A[k,l] -= d*A[i,l]` | Compound assignment operators. | `j = j + 1`, `A[i,k] = A[i,k]/d`, `A[k,l] = A[k,l] - d*A[i,l]` | No. |
| 73 | `A[i, k], A[mi, k] = A[mi, k], A[i, k]` | One-line tuple swap. | `tmp = A[i,k]; A[i,k] = A[mi,k]; A[mi,k] = tmp;` | No. |
| 99 | bare `A` as the last line | Implicit return. | `return A` | No. |
| 45-100 | single-letter names `nr, nc, m, mi, d, l` | Students must decode each name. | `number_of_rows`, `number_of_cols`, `largest_value`, `pivot_row`, `pivot`, `multiplier` | No. |
| 185 | `AD = A;` | Looks like a copy but binds the same array; it is safe only because `AD` is later rebound, never mutated. | `AD = copy(A);` | No (one extra copy). |
| 191-193 | `Fₒ = qr(AD)`, `Qₒ = Matrix(Fₒ.Q)`, `λ = diag(Qₒ)` | Starts the convergence check from the diagonal of `Q`, which has no meaning as an eigenvalue estimate, and computes the same factorization the loop computes again. Subscript names `Fₒ`, `Qₒ` are hard to type. | `λ = diag(A);` | Yes, slightly: the first convergence comparison changes, so the iteration count could change. |
| 200, 206-217 | `Matrix(F.Q)` and `λ′` | The prime character `′` is hard to type; `Matrix(F.Q)` is needed because `qr` stores `Q` compactly. | Rename `λ′` to `λ_new`; keep `Matrix(F.Q)` with its comment. | No. |
| 228 | `Matrix{Float64}(I, number_of_rows, number_of_rows)` | Constructor call with the `I` (UniformScaling) object. | `A - λ[i]*I` (no matrix needed), or build the identity with a loop. | No: same values. |
| 240 | `AM = [AH b];` | Horizontal concatenation literal. | `AM = hcat(AH, b);` | No. |
| 244 | `_rref!(AM)[:,end]` | Index applied directly to a call's result, and the call mutates `AM`. | `reduced = _rref!(AM); EVUS = reduced[:, number_of_rows + 1];` | No. |
| 251 | `((-1)^(i+1))*(1/d)*EVUS` | Sign trick with no stated reason. | `sign = 1.0; if (iseven(i) == true) sign = -1.0; end; eigenvectors[i] = sign*(1/d)*EVUS` | No, if `(1/d)*EVUS` is kept (writing `EVUS/d` can change the last bit). |

Not syntax, but found while documenting: on the symmetric matrix `[4.0 1.0 0.5; 1.0 3.0 0.2; 0.5 0.2 1.0]` with `maxiter = 100`, `qriteration` returns an all-`NaN` eigenvector for the smallest eigenvalue. `_rref!` treats `A − λᵢI` as singular, the last column of the reduced matrix comes out all zeros, and the code divides by its zero length. The docstring now says this can happen.

Verdict: rewrite recommended.

## Syntax audit: code/src/Factory.jl

Line numbers refer to the commented file.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 132 | `push!(puncuation_skip_set, '\"');` | The backslash is not needed inside single quotes, so the character looks like part of a string. | `push!(puncuation_skip_set, '"');` | No. Same character. |
| 138 | `push!(puncuation_skip_set, ''');` | Three quote marks in a row read as a typo. | `push!(puncuation_skip_set, '\'');` with the comment "the apostrophe". | No. Same character. |
| 165 | `push!(puncuation_skip_set, ' ');` (the character is U+00A0) | The character is an invisible non-breaking space that looks exactly like an ordinary space. A reader concludes that the cleaner deletes every space, which it does not. | `push!(puncuation_skip_set, ' ');` | No. Same character, now visible in the source. |
| 169 | `chararray = headlinerecord \|> collect;` | The pipe `\|>` puts the function after its argument. | `chararray = collect(headlinerecord);` | No. |
| 177-178 | `filter(c -> (c \|> Int ) ≤ 255 && !(c ∈ puncuation_skip_set), chararray) \|> String \|> string-> strip(string, ' ') \|> String;` | Two anonymous functions, a three-stage pipe chain, `&&` inside a predicate, and a lambda parameter named `string` that hides the `string` function. | `kept = Char[]; for c ∈ chararray; if (Int(c) ≤ 255 && in(c, puncuation_skip_set) == false); push!(kept, c); end; end; headlinerecord = String(strip(String(kept), ' '));` | No. Same characters kept, same result type `String`. |
| 182-183 | `fields = split(headlinerecord, ' ') .\|> String` then `fields = filter(x -> x != "", fields)` | A broadcast pipe `.\|>` and an anonymous function. | `fields = String[]; for piece ∈ split(headlinerecord, ' '); if (piece != ""); push!(fields, String(piece)); end; end;` | No. Same words in the same order. |
| 226-227 | `build(record::Type{T}, data::NamedTuple)::T where T <: AbstractTextRecordModel` that only calls `_build(record, data)` | A generic method that forwards to a private helper with a single method. A reader must find a second function to see any work. | Rename the helper at line 114 to `build(recordtype::Type{MySarcasmRecordModel}, data::NamedTuple)::MySarcasmRecordModel` and delete the forwarding method. | Only for a text record type with no `_build` method (none exists): the `MethodError` would name `build` instead of `_build`. |
| 266 | `build(modeltype::Type{T}, data::NamedTuple) where T <: AbstractLinearProgrammingProblemType` | `where T` dispatch for a family that has one member. | `build(modeltype::Type{MyLinearProgrammingProblemModel}, data::NamedTuple)::MyLinearProgrammingProblemModel` | No for current callers. A future subtype would need its own method. |
| 445, 465, 678, 697, 726 | `for (_,v) ∈ edgemodels` | Unpacking a `key => value` pair, with `_` as a throwaway name. | `for v ∈ values(edgemodels)` | No. `values` walks the dictionary in the same order. |
| 449, 682 | `list_of_node_ids = tmp_node_ids \|> collect \|> sort;` | A pipe chain. | `list_of_node_ids = sort(collect(tmp_node_ids));` | No. |
| 462, 694 | `[nodes[nodeidmap[id]] = MyGraphNodeModel(nodeidmap[id], nothing) for id ∈ list_of_node_ids];` | A comprehension used only for its side effect. It builds an array that is thrown away, and the assignment hides inside the brackets. | `for id ∈ list_of_node_ids; newid = nodeidmap[id]; nodes[newid] = MyGraphNodeModel(newid, nothing); end` | No. It also skips building the discarded array. |
| 792-796 | `haskey(data, :𝒮) == false ? m.𝒮 = Array{Int64,1}(undef,1) : m.𝒮 = data[:𝒮];` (five lines) | A ternary with an assignment in each branch. Students cannot tell where the condition ends. | `if (haskey(data, :𝒮) == true); m.𝒮 = data.𝒮; else; m.𝒮 = Array{Int64,1}(undef,1); end` for each of the five keys. | No. |
| 792-795 | `Array{Int64,1}(undef,1)`, `Array{Float64,3}(undef,1,1,1)`, `Array{Float64,2}(undef,1,1)` | Placeholders that hold whatever bits were in memory. The model looks valid but holds meaningless numbers. | `zeros(Int64, 1)`, `zeros(1, 1, 1)`, `zeros(1, 1)` | Yes, the placeholder values become 0 instead of arbitrary values. No caller reads a placeholder. |
| 848-850 | `nrows = data[:nrows]` (also `ncols`, `rewards`) | Indexing a NamedTuple with a Symbol, while other methods in the file use `data.nrows`. | `nrows = data.nrows;` | No. |
| 851 | `defaultreward = haskey(data, :defaultreward) == false ? -1.0 : data[:defaultreward]` | A ternary inside an assignment. | `defaultreward = -1.0; if (haskey(data, :defaultreward) == true); defaultreward = data.defaultreward; end` | No. |
| 1283-1297 | `for key ∈ fieldnames(modeltype) ... setproperty!(model, key, value)` | A reflection loop over Symbols. The field names never appear in the code, so a reader cannot see which keys are required. | Five explicit blocks in field order: `if (haskey(data, :states) == false); throw(ArgumentError("NamedTuple is missing: states")); end; model.states = data.states;` and the same for `actions`, `γ`, `α`, and `Q`. Keep the `isempty(data)` check around them. | No. The error messages and the order of the checks stay the same. |
| 1290 | `"NamedTuple is missing: $(field_name_string)"` | String interpolation with a dollar sign. | `"NamedTuple is missing: " * field_name_string` | No. (The rewrite in the row above removes this line.) |
| 1356 | `Y = ⊗(linearimagecollection[:,j], linearimagecollection[:,j]);` | A Unicode operator from a loaded package, called like a function, with no sign of its origin. | `x = linearimagecollection[:,j]; Y = x * transpose(x);` | No. Same values and same element type. |
| 1362 | `W[i,i] = 0.0f0;` | The `f0` suffix of a `Float32` literal. | `W[i,i] = 0.0;` | No. `W` holds `Float32` numbers, so Julia converts the `0.0`. |
| 1452-1462 | `for key ∈ fieldnames(modeltype) ... value = nothing ... setproperty!(model, key, value)` | The same reflection loop, with `nothing` as a silent default. | Write the work into the `VLLinearUtilityFunction` method: `if (isempty(data) == false); if (haskey(data, :α) == true); model.α = data.α; else; model.α = nothing; end; end` | No for `VLLinearUtilityFunction`, the only utility type. A new utility type would need its own method. |
| 1491 | `build(model::Type{VLLinearUtilityFunction}, data::NamedTuple)::VLLinearUtilityFunction = _build(model, data)` | A one-line short-form definition that forwards to a private helper. | A full `function build(...) ... end` block that holds the explicit body from the row above. | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/Files.jl

Line numbers refer to the commented file.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 73 | `open(filepath, "r") do io ... end` | A `do` block hides an anonymous function that `open` calls with the open file. Students do not see where `io` comes from or that the file is closed for them. | `for line ∈ readlines(filepath)` then the same loop body. `readlines` opens the file, returns every line as a `String`, and closes the file. | No. Same lines, same `SystemError` for a missing file. The whole file is held in memory at once (these are small text files). |
| 75 | `push!(result, strip(line))` | `strip` returns a `SubString`, which `push!` silently converts to `String`. | `clean_line = String(strip(line)); push!(result, clean_line);` | No. |
| 98 | `return load(path)` | Three loaded packages (FileIO, JLD2, Images) export `load`; a student cannot tell which one runs. | `return FileIO.load(path);` | No. JLD2 re-exports the FileIO function, so this is the same function. |
| 118 | `_file_extension(file::String) = file[findlast(==('.'), file)+1:end];` | One-line short-form definition; `==('.')` is a partially applied function; index arithmetic inside the brackets; a name with no period fails with a cryptic `MethodError` (`nothing + 1`). | A full `function` block: `parts = split(file, '.'); extension = String(parts[end]); return extension;` | Yes, for a name with no period: the rewrite returns the whole name instead of throwing. The MNIST loader then skips that file, as it skips any non-jpg file. |
| 139 | `MyTrainingMarketDataSet() = _jld2(joinpath(_PATH_TO_DATA, "..."));` | Short-form definition with a call nested in a call. | A `function` block: `path = joinpath(_PATH_TO_DATA, "SP500-Daily-OHLC-1-3-2014-to-12-31-2024.jld2"); data = _jld2(path); return data;` | No. |
| 189, 205, 228, 247 | `return CSV.read(joinpath(_PATH_TO_DATA, "..."), DataFrame)` | Nested call, and a type (`DataFrame`) passed as an ordinary argument. | `path = joinpath(_PATH_TO_DATA, "..."); df = CSV.read(path, DataFrame); return df;` | No. |
| 275 | `list_of_words = keys(data) \|> collect;` | The pipe `\|>` reads right to left from what students expect. | `list_of_words = collect(keys(data));` | No. |
| 332, 415 | `if !isfile(filepath)` | `!` as "not" is easy to miss; the course style writes `== false`. | `if (isfile(filepath) == false)` | No. |
| 342, 425 | `open(filepath, "r") do file ... end` | `do` block, as at line 72. | `for line ∈ eachline(filepath)`. With a path, `eachline` opens the file and closes it when the loop finishes. | No for the normal case. If the parser throws partway through, the file closes later (when Julia cleans up) rather than at once. |
| 346, 429 | `if (contains(line, comment) == true) \|\| (isempty(line) == true)` | The rule skips a line that holds the comment character anywhere, not only at the start; the `\|\|` hides this. | `is_comment = contains(line, comment); is_blank = isempty(line); if (is_comment == true \|\| is_blank == true) continue; end`, with a comment that a comment character anywhere skips the line. | No. (Switching to `startswith` would change behavior: a data line with a trailing `# note` would then reach the parser.) |
| 351, 434 | `(s,t,data) = edgeparser(line, delim);` | Tuple unpacking of a callback's result. If the parser returns `nothing` (the L4b `parse_edge_record` does for a bad line), the error is a cryptic `MethodError` about `iterate(::Nothing)`. | `parsed = edgeparser(line, delim); if (isnothing(parsed) == true) throw(ArgumentError("could not parse the line: $(line)")); end; s = parsed[1]; t = parsed[2]; data = parsed[3];` | Error type and message only: `ArgumentError` with the bad line instead of `MethodError`. |
| 355, 438 | `edges[linecounter] = build(MyGraphEdgeModel, (source = s, ...));` | A type passed as an argument, with a NamedTuple built inside the call. | `edge_data = (source = s, target = t, weight = data, id = linecounter); edge = build(MyGraphEdgeModel, edge_data); edges[linecounter] = edge;` | No. |
| 363, 448, 505 | `linecounter += 1` | Compound assignment. | `linecounter = linecounter + 1;` | No. |
| 487 | `range(0, stop=9, step=1) \|> collect` | Keyword range constructor plus a pipe, for the list 0 to 9. | `number_digit_array = collect(0:9);` | No. |
| 495 | `Array{Gray{N0f8},3}(undef, 28, 28, number_of_examples)` | `undef` arrays hold arbitrary values. A non-jpg file leaves its slice unset, so garbage pixels reach the student. | `image_digit_array = zeros(Gray{N0f8}, number_of_rows, number_of_cols, number_of_examples);` | Yes, only for slices whose file is not a jpg: they become black (0) instead of arbitrary values. |
| 496, 504 | `"$(i)"` | String interpolation used only to turn a number into text. | `folder_name = string(i);` | No. |
| 497, 505 | `imagecount = 1` ... `imagecount += 1` | A counter that is never read; students look for its purpose. | Delete both lines. | No. |
| 504 | `joinpath(pathtoimages, "$(i)", filename) \|> x-> FileIO.load(x)` | Pipe into an anonymous function. | `image_path = joinpath(pathtoimages, string(i), filename); image = FileIO.load(image_path); image_digit_array[:,:,fileindex] = image;` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/FlowValidation.jl

Line numbers refer to the commented file. Nothing below has been applied.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 57 | `fields = strip.(split(record, delimiter))` | A broadcast dot on a nested call. | `pieces = split(record, delimiter)`, `fields = Array{SubString{String},1}()`, `for piece in pieces` / `push!(fields, strip(piece))` / `end` | Type: the same `Vector{SubString{String}}` when the element type is written as shown. |
| 58 | `length(fields) == 5 \|\| throw(ArgumentError(...))` | `\|\|` used as control flow. | `if (length(fields) != 5)` / `throw(ArgumentError(...))` / `end` | No. |
| 105 | `isfile(path) \|\| throw(ArgumentError(...))` | `\|\|` used as control flow. | `if (isfile(path) == false)` / `throw(ArgumentError(...))` / `end` | No. |
| 106, 107 | `source isa Bool && throw(...)`, `sink isa Bool && throw(...)` | `&&` used as control flow. | One `if (... isa Bool)` / `throw(...)` / `end` block each. | No. |
| 114 | `return build(MyDirectedBipartiteGraphModel, (s = Int(source), t = Int(sink), edges = edges))` | A nested call with an inline NamedTuple and two conversions inside it. | `data = (s = Int(source), t = Int(sink), edges = edges)`, `graph = build(MyDirectedBipartiteGraphModel, data)`, `return graph` | No. |
| 170 | `source_id, sink_id = Int(source), Int(sink)` | Two assignments in one tuple statement. | `source_id = Int(source)` and `sink_id = Int(sink)` on two lines. | No. |
| 171 | `source_id == sink_id && throw(ArgumentError(...))` | `&&` used as control flow. | `if (source_id == sink_id)` / `throw(ArgumentError(...))` / `end` | No. |
| 172 | `atol >= 0 \|\| throw(ArgumentError(...))` | `\|\|` used as control flow. | `if (atol < 0)` / `throw(ArgumentError(...))` / `end` | No for numbers. For `atol = NaN` the original throws and `atol < 0` does not; use `if ((atol >= 0) == false)` to keep that. |
| 178 | `for (edge, (_, upper)) in graph.capacity` | Nested unpacking of a pair whose value is itself a tuple, with `_` discarding the lower bound. | `for (edge, bounds) in graph.capacity`, then `upper = bounds[2]` | No. |
| 179, 202 | `value = get(flow, edge, 0.0)` and later `value = -residuals[source_id]` | One name, `value`, means an edge flow inside the loop and the flow value after it. | Rename the loop variable `edge_flow`. | No. |
| 180 | `capacity_ok &= value >= -atol && value <= upper + atol` | The `&=` operator, plus `&&` inside it; precedence is not obvious. | `if ((value >= -atol && value <= upper + atol) == false)` / `capacity_ok = false` / `end` | No, written with the negated combined test as shown. |
| 185 | `capacity_ok &= all(edge -> haskey(graph.capacity, edge), keys(flow))` | `&=`, `all`, and an anonymous function in one line. | `for edge in keys(flow)` / `if (haskey(graph.capacity, edge) == false)` / `capacity_ok = false` / `end` / `end` | No. |
| 193, 196 | `incoming = sum((get(flow, edge, 0.0) for edge in keys(graph.capacity) if edge[2] == vertex); init = 0.0)` and the matching `outgoing` line | A generator with a filter inside `sum`, plus the `init` keyword. | `incoming = 0.0` and `outgoing = 0.0`, then `for edge in keys(graph.capacity)` / `if (edge[2] == vertex)` / `incoming = incoming + get(flow, edge, 0.0)` / `end` / `if (edge[1] == vertex)` / `outgoing = outgoing + get(flow, edge, 0.0)` / `end` / `end` | No. Both add the terms one at a time in the order of `keys(graph.capacity)`, so the floating-point sums match. |
| 207-210 | `conservation_ok = all(vertex in (source_id, sink_id) \|\| abs(residuals[vertex]) <= atol for vertex in keys(residuals))` | A generator inside `all`, with `\|\|` used to exempt the source and sink. | `conservation_ok = true`, then `for vertex in keys(residuals)` / `if (vertex != source_id && vertex != sink_id)` / `if (abs(residuals[vertex]) > atol)` / `conservation_ok = false` / `end` / `end` / `end` | No for numbers. A `NaN` residual makes the original `false`; `abs(NaN) > atol` is also false, so write the inner test as `if ((abs(residuals[vertex]) <= atol) == false)` to keep that. |
| 217 | `valid = capacity_ok && conservation_ok && balance_ok` inside the returned NamedTuple | A computed field inside the return statement. | `valid = capacity_ok && conservation_ok && balance_ok` on its own line before `return`, then `valid = valid` in the NamedTuple. | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/FluxBalance.jl

Line numbers refer to the commented file. Both functions are called by the L6b lab through `weeks/week-06/L6b/src/Compute.jl` and by the week 6 validation tests.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 69-70, 142-143 | `AbstractMatrix{<:Real}`, `AbstractVector{<:Real}` | Parametric abstract types with `<:`. | `Array{Float64,2}` and `Array{Float64,1}`, matching the course style. | Yes: type. It would reject integer arrays, views, and sparse matrices that the functions accept now. Check what type `model.S` has in L6b before changing. |
| 75-76 | `length(lower) == length(upper) == length(c) == n \|\|` + `throw(...)` on the next line | Chained `==` and a `\|\|` guard split over two lines. | `if (length(lower) != n \|\| length(upper) != n \|\| length(c) != n) throw(DimensionMismatch("...")); end` | No. |
| 77 | `all(lower .<= upper) \|\| throw(...)` | Broadcast comparison, `all`, and a `\|\|` guard. | `for j ∈ 1:n; if ((lower[j] <= upper[j]) == false) throw(ArgumentError("...")); end; end` | No, if written as `(lower[j] <= upper[j]) == false`. Writing `lower[j] > upper[j]` would let a NaN bound pass. |
| 78-79 | `any(==(Inf), lower) && throw(...)` | Partially applied `==(Inf)`, `any`, and `&&` as an if. | `for j ∈ 1:n; if (lower[j] == Inf) throw(ArgumentError("a lower bound cannot be Inf")); end; end`, then a second loop for the upper bounds. | No, if the two loops stay separate (one combined loop could report the upper-bound error first). |
| 86 | `v = JuMP.@variable(model, v[1:n])` | `v` on both sides; the macro already creates the local `v`. | `JuMP.@variable(model, v[1:n])` | No. |
| 91-92 | `isfinite(lower[j]) && JuMP.set_lower_bound(v[j], lower[j])` | `&&` used as an if (objected). | `if (isfinite(lower[j]) == true) JuMP.set_lower_bound(v[j], lower[j]); end` | No. |
| 97 | `JuMP.@constraint(model, S * v .== 0)` | Broadcast `.==` that makes one constraint per species, inside a macro. | Comments enough. A per-row loop is longer and not clearer. | A loop could build the constraint matrix differently and, when several flux vectors are optimal, change which one GLPK returns. |
| 100 | `sum(c[j] * v[j] for j in 1:n)` | Generator inside `sum` (objected), inside a macro. | `JuMP.@objective(model, Max, dot(c, v))` (`dot` is available from the package's `using LinearAlgebra`) | No: the same linear program. |
| 107 | `status == _FBA_MOI.OPTIMAL \|\| return (...)` | Early return hidden in a `\|\|` (the objected `&& return` pattern). | `if (status != _FBA_MOI.OPTIMAL) return (status = status, optimal = false, flux = nothing, objective = nothing); end` | No. |
| 110 | `flux = JuMP.value.(v)` inside the return NamedTuple | Broadcast call inside a return literal. | `flux = zeros(n); for j ∈ 1:n; flux[j] = JuMP.value(v[j]); end`, then return. | No. |
| 146-147 | chained `==` with a `\|\|` guard on the next line | As at lines 75-76. | if-block with `!=` tests. | No. |
| 151 | `maximum(abs, S * flux; init = 0.0)` | A function argument (`abs`) and the `init` keyword. | `residual = S * flux; maximum_residual = 0.0; for i ∈ 1:length(residual); if ((abs(residual[i]) <= maximum_residual) == false) maximum_residual = abs(residual[i]); end; end` | Yes, unless written as shown: with `if (abs(r) > maximum_residual)`, a NaN residual is skipped and `balance_ok` becomes `true` for a NaN flux. `maximum` propagates NaN. |
| 156 | `all(lower[j] - atol <= flux[j] <= upper[j] + atol for j in eachindex(flux))` | Generator inside `all` with a chained comparison. | `bounds_ok = true; for j ∈ 1:length(flux); if ((lower[j] - atol <= flux[j] && flux[j] <= upper[j] + atol) == false) bounds_ok = false; end; end` | No (NaN fails both forms). |
| 159 | `valid = balance_ok && bounds_ok` inside the return NamedTuple | A boolean expression inside a return literal. | `valid = (balance_ok == true && bounds_ok == true);` on its own line, then return. | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/GraphRepresentation.jl

Line numbers refer to the commented file. Nothing below has been applied.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 34 | `const WeightedEdgeRecord = NamedTuple{(:source, :target, :weight), Tuple{Int64, Int64, Float64}}` | A parametric `NamedTuple` type written with a tuple of symbols and a tuple of types; hard to read as "a record with three named fields". | `const WeightedEdgeRecord = @NamedTuple{source::Int64, target::Int64, weight::Float64}` | No. The macro builds the same type. |
| 69 | `isfile(path) \|\| throw(ArgumentError(...))` | `\|\|` used as control flow: "if the file does not exist, stop". | `if (isfile(path) == false)` / `throw(ArgumentError(...))` / `end` | No. |
| 76 | `for (line_number, raw_line) in enumerate(eachline(path))` | `enumerate` pairs each line with a counter, unpacked into two loop variables. | `line_number = 0` before the loop; `for raw_line in eachline(path)` with `line_number = line_number + 1` as the first line of the body. | No, as long as the counter is updated before the `continue` on line 80. |
| 80 | `(isempty(line) \|\| startswith(line, '#')) && continue` | `&&` used as control flow, combined with an `\|\|` test. | `if (isempty(line) == true \|\| startswith(line, '#') == true)` / `continue` / `end` | No. |
| 84 | `fields = strip.(split(line, delimiter))` | A broadcast dot on a nested call. | `pieces = split(line, delimiter)`, `fields = Array{SubString{String},1}()`, `for piece in pieces` / `push!(fields, strip(piece))` / `end` | Type: the same `Vector{SubString{String}}` when the element type is written as shown. |
| 85 | `length(fields) == 3 \|\| throw(ArgumentError(...))` | `\|\|` used as control flow. | `if (length(fields) != 3)` / `throw(ArgumentError(...))` / `end` | No. |
| 94-96 | `isnothing(source) && throw(ArgumentError(...))` (three lines) | `&&` used as control flow. | `if (isnothing(source) == true)` / `throw(ArgumentError(...))` / `end`, one block per field. | No. |
| 97 | `isfinite(weight) \|\| throw(ArgumentError(...))` | `\|\|` used as control flow. | `if (isfinite(weight) == false)` / `throw(ArgumentError(...))` / `end` | No. |
| 104 | `isempty(edges) && throw(ArgumentError(...))` | `&&` used as control flow. | `if (isempty(edges) == true)` / `throw(ArgumentError(...))` / `end` | No. |
| 139 | `push!(ids, Int64(edge.source), Int64(edge.target))` | `push!` with two values at once is easy to misread as a pair. | `push!(ids, Int64(edge.source))` and `push!(ids, Int64(edge.target))` on two lines. | No. |
| 143 | `return sort!(collect(ids))` | A nested in-place call. | `id_vector = collect(ids)`, `sort!(id_vector)`, `return id_vector` | No. |
| 173 | `result = Dict(id => Int64[] for id in vertex_ids(edges))` | A dictionary comprehension (generator of pairs). | `result = Dict{Int64, Vector{Int64}}()`, then `for id in vertex_ids(edges)` / `result[id] = Int64[]` / `end` | No. The comprehension already gives `Dict{Int64, Vector{Int64}}`. |
| 183 | `sort!(unique!(neighbors))` | A nested pair of in-place calls; the order of the two steps is easy to miss. | `unique!(neighbors)` then `sort!(neighbors)` on two lines. | No. |
| 225 | `positions = Dict(id => index for (index, id) in enumerate(ids))` | A dictionary comprehension over `enumerate`, with the pair order reversed from the loop variables. | `positions = Dict{Int64, Int64}()`, then `for index in 1:length(ids)` / `positions[ids[index]] = index` / `end` | No. |
| 268, 269, 276 | `number_of_vertices >= 0 \|\| throw(...)`, `number_of_edges >= 0 \|\| throw(...)`, `number_of_edges <= maximum_edges \|\| throw(...)` | `\|\|` used as control flow. | One `if (...)` / `throw(...)` / `end` block per check, with the condition negated. | No. |
| 272 | `number_of_vertices <= 1 && return 0.0` | `&&` used as an early return. | `if (number_of_vertices <= 1)` / `return 0.0` / `end` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/Graphs.jl

Line numbers refer to the commented file. Nothing below has been applied.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 82, 352, 370 | `for (k, _) ∈ edges` / `for (k, _) ∈ graph.edges` | Unpacks each dictionary pair into a key and a throwaway `_`; students must know that looping over a `Dict` gives `key => value` pairs. | `for k in keys(edges)` | No. `keys(d)` visits the keys in the same order as looping over `d`. |
| 259 | `for (k, _) ∈ graph.nodes` | Same pair unpacking; the original comment asked "what is this?". | `for k in keys(graph.nodes)` | No. |
| 338 | `for (_, node) ∈ nodes` | Same pair unpacking, dropping the key instead. | `for node in values(nodes)` | No. |
| 247-249 | `for ((source, target), _) in graph.edges` followed by `weight(graph, source, target) < 0 &&` / `throw(...)` split over two lines | Nested unpacking of a pair whose key is itself a tuple, then a two-line `cond && throw(...)`. | `for edge in keys(graph.edges)`, `source = edge[1]`, `target = edge[2]`, `if (weight(graph, source, target) < 0)` / `throw(ArgumentError(...))` / `end` | No. |
| 366 | `changed \|\| break` | `\|\|` used as control flow: "if changed is false, break". | `if (changed == false)` / `break` / `end` | No. |
| 449, 533 | `u == t && break` | `&&` used as control flow. | `if (u == t)` / `break` / `end` | No. |
| 683, 740 | `found \|\| break` | `\|\|` used as control flow. | `if (found == false)` / `break` / `end` | No. |
| 441, 523 | `n = size(R,1); size(R,2) == n \|\| throw(ArgumentError("R must be square"))` | Two statements on one line, and the second is a `cond \|\| throw(...)` one-liner. | `n = size(R,1)` on its own line, then `if (size(R,2) != n)` / `throw(ArgumentError("R must be square"))` / `end` | No. Same error type and message. |
| 444, 526, 527, 532, 541 | `stack = Int[s]; seen[s] = true`, `q = Vector{Int}(undef, n); head = 1; tail = 1`, `q[tail] = s; tail += 1`, `u = q[head]; head += 1`, `q[tail] = v; tail += 1` | Several statements per line hide the steps; `Vector{Int}(undef, n)` makes an unfilled vector. | One statement per line; `q = zeros(Int, n)` instead of `Vector{Int}(undef, n)`. | No. `zeros` fills the slots with 0, which are never read before they are written. |
| 453, 537, 603 | `@inbounds for v in 1:n` and `@inbounds begin ... end` | A macro that turns off index checking; students cannot tell what it does or when it is safe. | Drop `@inbounds` (and the `begin`/`end` around the four updates at 603). | Performance only: index checks come back on, which is slightly slower. A bad index would raise `BoundsError` instead of reading invalid memory. |
| 437, 519, 593, 668, 725 | `where {T<:Real}` with `atol::T=zero(T)`, `zero(T)`, `zeros(T, n, n)`, `Matrix{T}(C)` | Generic code over a number type `T`; students must follow a type parameter through the whole function. | Write the maximum-flow helpers for `Float64` only: `R::Array{Float64,2}`, `atol::Float64 = 0.0`, `0.0` for `zero(T)`, `copy(C)` for `Matrix{T}(C)`. | Type: the helpers would accept only `Float64` matrices. `maximumflow` always builds a `Float64` matrix, so the course results do not change. |
| 470, 554 | `Δ = typemax(T)` | `typemax` of a type parameter is abstract; the reader must know it is `Inf` here. | `Δ = Inf` (with the `Float64` rewrite above). | No for `Float64`. |
| 635 | `flows = [(u, v, F[u,v]) for u in 1:n, v in 1:n if C[u,v] > 0 && F[u,v] > 0]` | A two-index comprehension with a filter in one line. | `flows = Array{Tuple{Int64,Int64,Float64},1}()`, then `for u in 1:n` / `for v in 1:n` / `if (C[u,v] > 0 && F[u,v] > 0)` / `push!(flows, (u, v, F[u,v]))` / `end` / `end` / `end` | Order and type: the loops visit the pairs in a different order than the comprehension, but the `sort!` on the next line gives the same final order. The element type must be written as `Tuple{Int64,Int64,Float64}`, which matches what `maximumflow` produces. |
| 847 | `return graph.edges[(source, target)][1]` | Indexing a number with `[1]` returns the number itself; it looks like the code is taking the first entry of a collection. | `return graph.edges[(source, target)]` | Type: none for the graphs that `build(...)` makes, which store a number. It would differ only if a graph stored a tuple or vector per edge. |
| 818 | `if edge_id === nothing` | `===` (identity) is unfamiliar next to `==`. | `if (isnothing(edge_id) == true)` | No. |
| 1005-1006 | `for (edge, value) ∈ graph.capacity` / `C[edge[1], edge[2]] = value[2]` | Positional indexing `edge[1]`, `edge[2]`, `value[2]` hides what each number means. | `for (edge, bounds) ∈ graph.capacity`, `source_id = edge[1]`, `target_id = edge[2]`, `upper = bounds[2]`, `C[source_id, target_id] = upper` | No. |
| 242, 328, 945 | Two `_search` methods selected by the type of `algorithm` (`::DijkstraAlgorithm`, `::BellmanFordAlgorithm`), called as `_search(graph, start, algorithm)` | Multiple dispatch on a tag type: the call does not say which algorithm runs. | Rename the methods `_dijkstra(graph, start)` and `_bellman_ford(graph, start)`, and choose in `findshortestpath` with an if-block, as `walk` already does: `if algorithm isa DijkstraAlgorithm` / `return _dijkstra(graph, start)` / `elseif algorithm isa BellmanFordAlgorithm` / `return _bellman_ford(graph, start)` / `else` / `throw(ErrorException(...))` / `end` | Error type only: an unknown algorithm type would raise `ErrorException` instead of `MethodError`. |
| 668, 725, 1014 | Two `_flow` methods selected by the type of `algorithm`, identical except for one call (`_find_path_dfs` or `_find_path_bfs`) | Dispatch on a tag type, and 30 duplicated lines that students must compare by eye. | One `_flow(C, source, sink, use_bfs::Bool; atol)` function with `if (use_bfs == true)` / `found, parent, Δ = _find_path_bfs(...)` / `else` / `found, parent, Δ = _find_path_dfs(...)` / `end`; `maximumflow` sets `use_bfs = algorithm isa EdmondsKarpAlgorithm`. | Error type only, as above. |
| 94-882 (all graph functions) | `graph::T ... where T <: AbstractGraphModel` | A type parameter `T` used only to say "any graph type". | `graph::AbstractGraphModel`, with no `where` clause. | No. Julia still compiles a version for each concrete graph type. |

Verdict: rewrite recommended.

## Syntax audit: code/src/Hopfield.jl

Line numbers refer to the commented file. No notebook in this course calls these functions, so a rewrite here is lower priority than in the week-09 and week-10 files.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 47 | `s::Array{<: Number,1}` | `<:` inside a type parameter, here written with a space. The docstring now explains it. | Comments are enough. Optionally write `Array{<:Number,1}` the same way as the other arguments. | No. |
| 54 | `tmp = transpose(b)*s;` | A row vector times a column vector, stored in a variable named `tmp`. | `bias_term = dot(b, s);` | No. For two vectors, `transpose(b)*s` calls `dot`. |
| 83, 94, 177, 221 | `::Union{Nothing,Int64}`, `return nothing;`, and `if !isnothing(matched_memory_index)` | A function that returns either `nothing` or a number, tested with a negated `isnothing`. | Return `0` when no memory matches, and test `if (matched_memory_index > 0)`. | Yes: the return type of a private function changes. Its only two callers are in this file. |
| 88, 196 | `@view(memories[:,k])`, `dot(@view(W[j,:]), s)` | A macro that avoids a copy. | `memories[:, k]` and `dot(W[j, :], s)` | No change in values. Each call makes a copy, so it is slower, and `recover(...)` runs these lines on every iteration. |
| 157 | `patience_val = isnothing(patience) ? max(5, Int(round(0.1 * number_of_pixels))) : patience;` | A ternary, `isnothing`, and three nested calls on one line. | `patience_val = patience;` / `if (isnothing(patience) == true)` / `patience_val = max(5, Int(round(0.1*number_of_pixels)));` / `end` | No. |
| 158 | `min_iterations = max(isnothing(miniterations_before_convergence) ? patience_val : miniterations_before_convergence, patience_val);` | A ternary nested inside a function call. | `min_iterations = patience_val;` / `if (isnothing(miniterations_before_convergence) == false)` / `min_iterations = max(miniterations_before_convergence, patience_val);` / `end` | No. |
| 159 | `S = CircularBuffer{Array{Int32,1}}(patience_val);` | A parametric constructor from DataStructures.jl. The comment now explains what the buffer does. | Comments are enough. A plain alternative is a `Vector` with `push!`, plus `popfirst!` once it is full. | No, if the plain version keeps exactly the last `patience_val` states. |
| 165 | `falses(number_of_pixels)` | An unfamiliar constructor that returns a `BitVector`. | `fill(false, number_of_pixels)` | No change in values. The type becomes `Vector{Bool}`, which only this function uses. |
| 175, 219 | `isdefined(model, :memories)` | Reflection with a `Symbol`. | Comments are enough. `build(...)` always sets `memories`, so the check could be dropped. | Yes if dropped: a model built by hand without `memories` would fail with an `UndefRefError`. |
| 200-204 | `if iszero(h)` / `nothing;` / `else` / `s[j] = h > 0 ? Int32(1) : Int32(-1);` / `end` | An empty branch, then a ternary inside the other branch. | `if (h > 0)` / `s[j] = Int32(1);` / `elseif (h < 0)` / `s[j] = Int32(-1);` / `end` | Only if `h` is `NaN`: the original sets the spin to -1, and the rewrite keeps it. |
| 209, 243 | `fill!(visited_since_last_change, false);`, `all(visited_since_last_change)` | The `!` naming convention, and `all` over a vector of true/false values. The comments now explain both. | Comments are enough. | Not applicable. |
| 178, 223, 245, 253, 260, 352 | `@info "... $(matched_memory_index) ..."` and `@warn "..."` | Logging macros with string interpolation. | Comments are enough. `println(...)` is a plain alternative. | Yes with `println`: the messages go to standard output instead of the logger, and they lose the `[ Info:` and `┌ Warning:` format. |
| 179, 186, 267, 361 | `return frames, energydictionary`, the bare last line `frames, energydictionary`, and `return s,frames,probability` | A tuple without parentheses, and an implicit return on line 267. | `return (frames, energydictionary);` and `return (s, frames, probability);` | No. |
| 314 | `where T <: Number` | A type parameter that the body never uses. | `sₒ::Array{<:Number,1}` and delete `where T <: Number`. | No. `T` does not appear in the function body. |
| 323, 333 | `softmax(β*transpose(X)*s)` | Three operations nested inside one call. | `scores = β*transpose(X)*s;` / `p = softmax(scores);` | No. |
| 341, 346 | `norm(v, 1)`, `norm(v, 2)` | The second argument of `norm` picks the kind of length. The comments now explain it. | Comments are enough. | Not applicable. |

Verdict: rewrite recommended (low priority, because no notebook calls these functions). The ternaries at 157, 158, and 203 and the `Union{Nothing,Int64}` return are the main problems.

## Syntax audit: code/src/Indifference.jl

Line numbers refer to the commented file. No course notebook calls these functions.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 42 | `dependent::Array{T,1})::Float64 where T <: Real` | A type parameter `T` with `where`, after the return type. | `dependent::Array{Float64,1})::Float64` | Yes: type. Integer vectors would no longer be accepted. |
| 48 | `sum(α.*dependent)` | Broadcast multiply inside `sum`. | `total = 0.0; for i ∈ 1:length(α); total = total + α[i]*dependent[i]; end; return total;` | Possibly in the last bits: `sum` of an array may reorder additions. |
| 74 | `(U_model - utility).^2` | Broadcast power on a number. | `(U_model - utility)^2` | No. |
| 116 | `bounds::Array{T,2}, ... where T <: Real` | Type parameter on a keyword argument. | `bounds::Array{Float64,2}` | Yes: type. Integer bounds would be rejected. |
| 119 | `Int(floor((bounds[1,end] - bounds[1,1])/ϵ))` | Nested calls on one line, and `end` as an index. | `range_of_first_good = bounds[1,2] - bounds[1,1]; number_of_steps = Int(floor(range_of_first_good/ϵ));` | No, because `bounds` has two columns. |
| 126-127 | `inner_optimizer = NelderMead()` and `obj_function(x) = _obj_function(x, utility, model)` | An inner one-line function (a closure) that captures `utility` and `model` (objected). | No closure-free plain form: `optimize(...)` needs a function of `x` alone. Comments enough. | n/a |
| 149-150 | `L = tmp_bounds[:,1]; U = tmp_bounds[:,2];` | `U` here means upper bounds, while the file uses `U` for utility. | `lower = tmp_bounds[:,1]; upper = tmp_bounds[:,2];` | No. |
| 151 | `xₒ = (L .+ U)./2.0` | Broadcast `.+` and `./`, and the subscript name `xₒ`. | `x_start = (lower + upper)/2.0` (vector plus vector and vector divided by a number need no dots) | No: same arithmetic per entry. |
| 156-157 | `optimize(obj_function, L, U, xₒ, Fminbox(inner_optimizer), Optim.Options(...))` | Two constructor calls nested inside the call (objected nested calls). | `method = Fminbox(inner_optimizer); options = Optim.Options(time_limit = 600, show_trace = false, iterations = 100); results = optimize(obj_function, lower, upper, x_start, method, options)` | No. |
| 163 | `solution[i,:] .= x_best` | Broadcast assignment into a row. | `for j ∈ 1:number_of_features; solution[i,j] = x_best[j]; end` | No. |
| 166 | `base += ϵ` | Compound assignment. | `base = base + ϵ` | No. |

Not syntax, but found while documenting: with Optim 1.13.3 (the course environment), `Fminbox(NelderMead())` returns bundles outside their box. For `α = [0.55, 0.45]`, `utility = 1.0`, `bounds = [0.0 1.0; 0.0 3.0]`, `ϵ = 0.25`, rows 2-4 have first-good values 0.5875, 0.9625, 1.3375 (each above its box's upper edge, the last above the overall bound 1.0) and utilities 0.998, 1.204, 1.411. The docstring now warns about this. Syntax rewrites matter less here than this correctness problem.

Verdict: rewrite recommended.

## Syntax audit: code/src/LinearPrograms.jl

Line numbers refer to the commented file. No released notebook calls `solve_fruit_problem(...)`; the week 5 validation tests do.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 17 | `const MOI = JuMP.MOI` | A module alias defined as a constant. | Comments enough. | No rewrite proposed. |
| 65-66 | `AbstractVector{<:Real}` | Parametric abstract type with `<:`. | `Array{Float64,1}`, matching the course style. | Yes: type. It would reject `Int` vectors, ranges, and views that the function accepts now. |
| 71, 73-76 | `cond \|\| throw(...)` | The objected one-line guard; reads as a boolean expression, not a check. | `if (length(utilities) != length(prices)) throw(DimensionMismatch("...")); end` and the same if-block form for each check. | No, with the same messages and the same order of checks. |
| 72 | `isempty(utilities) && throw(...)` | `&&` used as an if. | `if (isempty(utilities) == true) throw(ArgumentError("...")); end` | No. |
| 73-76 | `all(isfinite, utilities)`, `all(>=(0), utilities)`, `all(>(0), prices)` | A function passed as an argument, and the partially applied comparison `>=(0)`. | `for value ∈ utilities; if (isfinite(value) == false) throw(ArgumentError("utilities must be finite")); end; end`, and likewise for the other tests. | No, if each test keeps its own loop in the original order (so the same error comes first). |
| 77 | `isfinite(budget) && budget >= 0 \|\| throw(...)` | Mixed `&&`/`\|\|` relies on precedence (an objected pattern). | `if (isfinite(budget) == false \|\| budget < 0) throw(ArgumentError("...")); end` | No (a NaN budget still throws through `isfinite`). |
| 81 | `u, p, available = Float64.(utilities), Float64.(prices), Float64(budget)` | Three assignments in one tuple assignment, plus broadcast conversion. | Three lines: `u = Float64.(utilities);` `p = Float64.(prices);` `available = Float64(budget);` | No. |
| 89 | `x = JuMP.@variable(model, x[1:n] >= 0)` | `x` appears on both sides; the macro already creates the local `x`. | `JuMP.@variable(model, x[1:n] >= 0)` | No. |
| 92, 95 | `sum(p[i] * x[i] for i in 1:n)` inside `@constraint` and `@objective` | Generator inside `sum` (objected), inside a macro. | `JuMP.@constraint(model, dot(p, x) <= available)` and `JuMP.@objective(model, Max, dot(u, x))` (`dot` is already imported) | No: the same linear program. Confirm the validation numbers after the change. |
| 100 | `status == MOI.OPTIMAL \|\| throw(ErrorException("... $(status)"))` | `\|\|` guard plus string interpolation. | `if (status != MOI.OPTIMAL) throw(ErrorException("fruit LP did not solve to optimality: $(status)")); end` | No. |
| 103 | `JuMP.value.(x)` | Broadcasting a function over a vector of variables. | `quantities = zeros(n); for i ∈ 1:n; quantities[i] = JuMP.value(x[i]); end` | No. |
| 107-113 | multi-line NamedTuple with `u ./ p` inside | Broadcast division inside a return literal. | `utility_per_dollar = zeros(n); for i ∈ 1:n; utility_per_dollar[i] = u[i]/p[i]; end`, then return `(quantities = quantities, ..., utility_per_dollar = utility_per_dollar)` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/MDP.jl

Line numbers refer to the commented file.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 63, 71 | `d = Categorical([0.25,0.25,0.25,0.25]);` then `aᵢ = rand(d);` | A distribution object from another package, used only to pick 1 to 4 uniformly. The four actions are hard-coded and the global generator is hidden. | `aᵢ = rand(1:4);` | Yes: random-draw stream. `rand(1:4)` uses different random numbers than `rand(Categorical(...))`, so the L11c rollout estimates (which seed the global generator) would change. |
| 66, 68, 81 | `should_choose_gain` flag loop | The name reads as "gain" (typo for "again"); the flag-driven `while` hides that this is draw-until-valid. | Rename to `should_draw_again`. | No. |
| 76, 122 | `current_position .+ Δ` | Broadcasting over tuples is unfamiliar; students expect `+` on numbers. | `new_position = (current_position[1] + Δ[1], current_position[2] + Δ[2]);` (the form used in L12a `GridWorld.jl`) | No: same `Tuple{Int,Int}`. |
| 87, 130 | `end;` after a function | The semicolon after `end` is noise and suggests it matters. | `end` | No. |
| 154, 188 | two `lookahead` methods, `U::Vector{Float64}` and `U::Function` | Multiple dispatch: the same name does two things depending on the type of `U`. | Comments enough; renaming (e.g. `lookahead_with_function`) would change the public API. | Renaming would break callers; L11d imports `lookahead`. |
| 165 | `sum(T[s,s′,a]*U[i] for (i,s′) in enumerate(𝒮))` | Generator inside `sum`, `enumerate`, tuple destructuring `(i,s′)`, and a mix of position `i` (for `U`) and state `s′` (for `T`). | `total = 0.0; for i ∈ 1:length(𝒮); s′ = 𝒮[i]; total = total + T[s,s′,a]*U[i]; end; return R[s,a] + γ*total;` (one statement per line) | No for non-empty `𝒮`: `sum` over a generator is a left-to-right fold, same as the loop. An empty `𝒮` would return `R[s,a]` instead of throwing. |
| 192 | `𝒮, T, R, γ = p.𝒮, p.T, p.R, p.γ;` | Four assignments packed into one tuple assignment. | Four lines: `𝒮 = p.𝒮;` `T = p.T;` `R = p.R;` `γ = p.γ;` | No. |
| 196 | `sum(T[s,s′,a]*U(s′) for s′ in 𝒮)` | Generator inside `sum`. | Explicit loop with a running `total`, as above. | No (same left fold). |
| 232, 280 | `Array{Float64,2}(undef, ...)`, `Array{Int64,1}(undef, NR)` | `undef` leaves garbage in memory until filled; students cannot tell that every entry gets set. | `Q_array = zeros(length(𝒮), length(𝒜));` and `π_array = zeros(Int64, NR);` | No, when the states and actions are numbered 1..n (every entry is filled). Negligible cost. |
| 235, 237 | `for i ∈ eachindex(𝒮)` then `s = 𝒮[i]` then `Q_array[s,a]` | `eachindex` is unfamiliar, and the loop index `i` is a position while the array index `s` is a state value. | `for s ∈ 𝒮` and `for a ∈ 𝒜` | No, under the 1..n numbering the code already assumes. |
| 244 | `sum([T[s,s′,a]*U[s′] for s′ in 𝒮])` | Comprehension inside `sum` (an objected pattern); it also builds a temporary array. | Explicit loop with a running `total`. | Possibly in the last bits: `sum` of an array may reorder additions (SIMD/pairwise), a loop adds left to right. In a grid world with exact ties in `Q`, a last-bit change could flip which action `policy(...)` returns. Compare `policy(Q(...))` before and after. |
| 277 | `(NR, _) = size(Q_array);` | Tuple destructuring with `_` to discard a value. | `NR = size(Q_array, 1);` | No. |
| 313 | `maximum(lookahead(problem, U, s, a) for a ∈ problem.𝒜)` | Generator inside `maximum` (objected pattern). | `best = -Inf; for a ∈ problem.𝒜; value = lookahead(problem, U, s, a); if (value > best) best = value; end; end; return best;` | Only for NaN or empty input: `maximum` returns NaN if any value is NaN and throws on an empty `𝒜`; the loop skips NaN and returns `-Inf` for an empty `𝒜`. |
| 349, 394 | `[0.0 for _ ∈ problem.𝒮]` | Comprehension with `_` to make a vector of zeros. | `U = zeros(length(problem.𝒮));` | No. |
| 352, 398 | `for _ ∈ 1:k_max` | `_` as a loop variable is unfamiliar. | `for k ∈ 1:k_max` | No. |
| 356, 399 | `U = [backup(problem, U, s) for s ∈ problem.𝒮]` (and the `lookahead` version) | The comprehension reads the old `U` while building the new one; that every value in a sweep uses the previous sweep is invisible. | `U_new = zeros(length(problem.𝒮)); for i ∈ 1:length(problem.𝒮); U_new[i] = backup(problem, U, problem.𝒮[i]); end; U = U_new;` | No, if written with a separate `U_new`. Writing into `U` in place would turn it into a Gauss-Seidel sweep and change the numbers. |
| 388-390 | `R = p.R; T = p.T; γ = p.γ;` in `iterative_policy_evaluation` | Unused locals: students look for where they are used. | Delete the three lines. | No. |
| 385 | untyped argument `π` | Students cannot tell what to pass. | Comments enough (the docstring now says "anything callable as `π(s)`"). | Adding a type such as `π::Function` would reject a `MyValueFunctionPolicy`. |
| 433 | `u, a = findmax(a->lookahead(problem, U, s, a), problem.𝒜);` | Anonymous function, `findmax(f, domain)` returning (value, position) in that order, and the name `a` used both for the lambda argument and the result. | `best_a = problem.𝒜[1]; best_u = lookahead(problem, U, s, best_a); for a ∈ problem.𝒜; value = lookahead(problem, U, s, a); if (value > best_u) best_u = value; best_a = a; end; end; return (a = best_a, u = best_u)` | Returns the action itself rather than its position (same when `𝒜 = 1..n`). Ties: both keep the first. NaN: `findmax` treats NaN as the maximum; the loop does not. |
| 455 | `(π::MyValueFunctionPolicy)(s::Int64) = greedy(π.problem, π.U, s).a;` | Makes a struct callable like a function (a functor), as a one-line method, and picks `.a` from a returned NamedTuple. | A named function: `function greedy_action(π::MyValueFunctionPolicy, s::Int64)::Int64; result = greedy(π.problem, π.U, s); return result.a; end` | Yes: API. Code that calls `π(s)`, e.g. `iterative_policy_evaluation(p, solution, k)`, would break. No course notebook calls it. |

Verdict: rewrite recommended.

## Syntax audit: code/src/Online.jl

Line numbers refer to the commented file. Students see this file through the L10b lab, which checks their `my_weighted_majority(...)` against `play(model, data)`. The zero-sum game `play(model)` is not called by any notebook.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 74, 171 | `weights = model.weights;` | The new name points to the model's own array, so every write to `weights` also changes `model.weights`. This hidden side effect is invisible in the code (the docstrings now state it). | Either keep it and keep the docstring note, or use `weights = copy(model.weights);` so `play(...)` leaves the model unchanged. | Yes with `copy`: `model.weights` would keep its starting values after the call. The L10b notebook and the week-10 tests use the returned array, but any code that reads `model.weights` after `play(...)` would change. |
| 97, 98 | `findall(x-> x == -1, expert_predictions) \|> i-> sum(weights[t, i]);` | Two anonymous functions joined by a pipe; the instructor has objected to closures and to `\|>` chains. | `weight_down_vote = 0.0;` / `weight_up_vote = 0.0;` / `for i ∈ 1:n` / `if (expert_predictions[i] == -1)` / `weight_down_vote = weight_down_vote + weights[t, i];` / `elseif (expert_predictions[i] == 1)` / `weight_up_vote = weight_up_vote + weights[t, i];` / `end` / `end` (the same loop the L10b students write) | Possibly in the last digits, because `sum` may add in a different order, and only an exact near-tie vote could flip. The L10b check `sims == sims_package` already passes with the students' loop on the lab data. |
| 99 | `aggregator_prediction = (weight_up_vote > weight_down_vote) ? 1 : -1;` | A ternary. | `aggregator_prediction = -1;` / `if (weight_up_vote > weight_down_vote)` / `aggregator_prediction = 1;` / `end` | No. |
| 107 | `results_array[t, end] = (aggregator_prediction == actual) ? 0 : 1;` | A ternary. Also, `end` inside the brackets means "the last column", which looks like the `end` of a block. | `mistake = 0;` / `if (aggregator_prediction != actual)` / `mistake = 1;` / `end` / `results_array[t, n+3] = mistake;` | No. |
| 112 | `loss[i] = (expert_predictions[i] == actual) ? 0.0 : 1.0;` | A ternary inside a loop. | `loss[i] = 0.0;` / `if (expert_predictions[i] != actual)` / `loss[i] = 1.0;` / `end` | No. |
| 182, 184 | `d = Categorical(p);` / `rand(d)` | A distribution object from Distributions.jl, and `rand` applied to it. The comments now explain both. | Comments are enough. | Not applicable. |
| 188 | `q = transpose(p) * M \|> vec;` | A pipe after a matrix product; the order of operations is not obvious. | `q = vec(transpose(p) * M);` | No. A hand-written double loop could change the last digits and so `argmin` on a near-tie. |
| 193-197 | `q̄ = zeros(Float64, n);` / `q̄[qstar] = 1.0;` / `l = L*q̄;` | A one-hot vector times a matrix hides the plain step "take column j⋆ of L". It also forces the payoff matrix to be square. | `l = -M[:, qstar];` | No for finite payoffs: the values are identical. The rewrite also removes the hidden requirement that `M` be `n × n`. |

Verdict: rewrite recommended. The closure-and-pipe vote at lines 97 and 98 and the three ternaries at 99, 107, and 112 are forms the instructor has objected to, and they sit in the one function that L10b students compare against.

## Syntax audit: code/src/QLearning.jl

Line numbers refer to the checked file. The file was rewritten in course style before this audit; the only edit was a trailing comment on line 116.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 58 | `ϵ::Union{Float64,Function} = 0.1` | A `Union` type: the argument may be a number or a function. | Comments enough; the docstring and the if-block at line 92 explain both cases. | n/a |
| 92 | `isa(ϵ, Function)` | A type test at run time. | Comments enough. | n/a |
| 111, 125 | `argmax(Q[s,:])`, `maximum(Q[s′,:])` | Row slices passed to `argmax`/`maximum`. | Comments enough; both are single calls on a named row, with comments. | n/a |
| 115 | `(s′, r) = worldmodel(problem, s, a, rng);` | Tuple destructuring of a returned pair. | Comments enough. | n/a |
| 137 | `return (Q = Q, visits = visits);` | NamedTuple literal. | Comments enough (already the plain form, not the `(; Q, visits)` shorthand). | n/a |

Verdict: comments enough.

## Syntax audit: code/src/Recursion.jl

Line numbers refer to the commented file. Nothing below has been applied.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 57, 58, 113, 161 | `n >= 0 \|\| throw(ArgumentError(...))`, `n <= 92 \|\| throw(...)` | `\|\|` used as control flow. | `if (n < 0)` / `throw(ArgumentError(...))` / `end`, and `if (n > 92)` / `throw(...)` / `end` | No. `n` is an `Int64` here. |
| 62 | `n == 0 && return series` | `&&` used as an early return. | `if (n == 0)` / `return series` / `end` | No. |
| 69, 125, 175, 258, 307 | `Base.Checked.checked_add(a, b)` | A function reached through a module path; students do not know `Base.Checked`. | Add `import Base.Checked: checked_add # addition that throws OverflowError instead of wrapping around` near the top, then call `checked_add(a, b)`. | No. The header comment now explains the function, so comments may be enough here. |
| 118, 120, 168, 170 | `return series[0] = 0`, `return series[1] = 1` | Returns the value of an assignment; students read it as returning the dictionary or a Bool. | `series[0] = 0` then `return series[0]` (and the same for key 1). | No. |
| 125 | `return series[n] = Base.Checked.checked_add(fibonacci!(n - 1, series), fibonacci!(n - 2, series))` | Assignment-as-return, a module-qualified call, and two recursive calls nested in one line. | `left = fibonacci!(n - 1, series)`, `right = fibonacci!(n - 2, series)`, `value = Base.Checked.checked_add(left, right)`, `series[n] = value`, `return value` | No. Julia already evaluates the two arguments left to right, so the call order is the same. |
| 164 | `haskey(series, n) && return series[n]` | `&&` used as an early return; this is the memoization step the notebook points to, so it should be the clearest line. | `if (haskey(series, n) == true)` / `return series[n]` / `end` | No. |
| 175-178 | `return series[n] = Base.Checked.checked_add(` with the two recursive calls on the next lines | Same as line 125. | Same rewrite as line 125, with `memoization_fibonacci!`. | No. |
| 202 | `function _fibonacci_index(n; maximum::Int)` | A keyword argument named `maximum` hides Julia's `maximum(...)` function inside the body. | Rename it `max_index`, and update the two callers (`max_index = 92`, `max_index = 40`). | No. `_fibonacci_index` is private. |
| 206 | `n isa Integer && !(n isa Bool) \|\| throw(ArgumentError(...))` | Mixed `&&` and `\|\|` on one line; the reader must know that `&&` binds first. | `if ((n isa Integer) == false \|\| (n isa Bool) == true)` / `throw(ArgumentError("n must be an integer index"))` / `end` | No. The condition is the logical opposite of the original test. |
| 209 | `0 <= n <= maximum \|\| throw(ArgumentError(...))` | A chained comparison combined with `\|\|` control flow. | `if (n < 0 \|\| n > maximum)` / `throw(ArgumentError(...))` / `end` | No. `n` is an integer at this point. |
| 245 | `index == 0 && return (value = Int64(0), additions = 0)` | `&&` used as an early return. | `if (index == 0)` / `return (value = Int64(0), additions = 0)` / `end` | No. |
| 249 | `previous, current = Int64(0), Int64(1)` | Two assignments in one tuple statement. | `previous = Int64(0)` and `current = Int64(1)` on two lines. | No. |
| 258 | `previous, current = current, Base.Checked.checked_add(previous, current)` | A simultaneous tuple assignment; students expect the left variable to change first. | `next_value = Base.Checked.checked_add(previous, current)`, `previous = current`, `current = next_value` | No. |
| 299, 304-308, 312 | `calls = Ref(0)`, the inner function `function visit(k::Int)::Int64 ... end` that changes `calls[]`, and `(value = visit(index), calls = calls[])` | A closure (an inner function that changes a variable of the outer function), a `Ref` box, and a NamedTuple whose second field depends on the first being evaluated first. | A top-level private function that returns both numbers: `function _fibonacci_with_calls(k::Int)::Tuple{Int64,Int}` / `if (k < 2)` / `return (Int64(k), 1)` / `end` / `(left, left_calls) = _fibonacci_with_calls(k - 1)` / `(right, right_calls) = _fibonacci_with_calls(k - 2)` / `return (Base.Checked.checked_add(left, right), left_calls + right_calls + 1)` / `end`. Then `(value, calls) = _fibonacci_with_calls(index)` and `return (value = value, calls = calls)`. | No for the values and counts (177 calls for `n = 10`). Performance: slightly different, from returning a tuple per call. |
| 306 | `k < 2 && return Int64(k)` | `&&` used as an early return. | Covered by the rewrite above: `if (k < 2)` / `return ...` / `end` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/ShortestPathAlgorithms.jl

Line numbers refer to the commented file. Nothing below has been applied.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 72, 73 | `source isa Bool && throw(ArgumentError(...))`, `target isa Bool && throw(...)` | `&&` used as control flow, inside an inner constructor. | `if (source isa Bool)` / `throw(ArgumentError(...))` / `end`, one block per argument. | No. |
| 74 | `isfinite(weight) \|\| throw(ArgumentError(...))` | `\|\|` used as control flow. | `if (isfinite(weight) == false)` / `throw(ArgumentError(...))` / `end` | No. |
| 103 | `weighted_edges(records) = [WeightedEdge(record...) for record in records]` | A one-line function definition, a comprehension, and splatting (`record...`) in one line. | `function weighted_edges(records)` / `edges = Array{WeightedEdge,1}()` / `for record in records` / `push!(edges, WeightedEdge(record[1], record[2], record[3]))` / `end` / `return edges` / `end` | Error behavior: splatting rejects a record with more or fewer than three entries (`MethodError`); indexing `record[1]`, `record[2]`, `record[3]` silently ignores a fourth entry. Add `if (length(record) != 3) throw(ArgumentError(...)) end` to keep a rejection. |
| 124 | `isempty(edges) && throw(ArgumentError(...))` | `&&` used as control flow. | `if (isempty(edges) == true)` / `throw(...)` / `end` | No. |
| 129 | `push!(vertices, edge.source, edge.target)` | `push!` with two values at once. | Two `push!` lines. | No. |
| 133 | `return sort!(collect(vertices))` | A nested in-place call. | `vertex_list = collect(vertices)`, `sort!(vertex_list)`, `return vertex_list` | No. |
| 161, 164 | `source isa Bool && throw(...)`, `source_id in vertices \|\| throw(...)` | `&&` and `\|\|` used as control flow. | One `if (...)` / `throw(...)` / `end` block each. | No. |
| 168 | `distances = Dict(vertex => Inf for vertex in vertices)` | A dictionary comprehension. | `distances = Dict{Int64, Float64}()`, then `for vertex in vertices` / `distances[vertex] = Inf` / `end` | No. The comprehension already gives `Dict{Int64, Float64}`. |
| 171 | `previous = Dict{Int64, Union{Nothing, Int64}}(vertex => nothing for vertex in vertices)` | A typed dictionary comprehension with a `Union` value type. | `previous = Dict{Int64, Union{Nothing, Int64}}()`, then `for vertex in vertices` / `previous[vertex] = nothing` / `end` | No. |
| 175, 231, 317 | `return source_id, vertices, distances, previous` and `_, vertices, distances, previous = _initialize(edges, source)` | Four values returned as an unnamed tuple; the caller must match the order, and `_` discards one value. | Return a plain NamedTuple, `return (source_id = source_id, vertices = vertices, distances = distances, previous = previous)`, and read fields: `start = _initialize(edges, source)`, `distances = start.distances`, and so on. | No. `_initialize` is private. |
| 228 | `any(edge -> edge.weight < 0, edges) && throw(ArgumentError(...))` | An anonymous function inside `any`, and `&&` used as control flow. | `for edge in edges` / `if (edge.weight < 0)` / `throw(ArgumentError(...))` / `end` / `end` | No. Both stop at the first negative weight with the same error. |
| 234 | `adjacency = Dict(vertex => WeightedEdge[] for vertex in vertices)` | A dictionary comprehension. | `adjacency = Dict{Int64, Vector{WeightedEdge}}()`, then a `for` loop that sets `adjacency[vertex] = WeightedEdge[]`. | No. |
| 251 | `vertex in visited && continue` | `&&` used as control flow. | `if (in(vertex, visited) == true)` / `continue` / `end` | No. |
| 329 | `isfinite(distances[edge.source]) \|\| continue` | `\|\|` used as control flow. | `if (isfinite(distances[edge.source]) == false)` / `continue` / `end` | No. |
| 339 | `changed \|\| break` | `\|\|` used as control flow. | `if (changed == false)` / `break` / `end` | No. |
| 387 | `source_id, target_id = Int64(source), Int64(target)` | Two assignments in one tuple statement. | `source_id = Int64(source)` and `target_id = Int64(target)` on two lines. | No. |
| 388, 389 | `haskey(previous, source_id) \|\| throw(...)`, `haskey(previous, target_id) \|\| throw(...)` | `\|\|` used as control flow. | One `if (haskey(...) == false)` / `throw(...)` / `end` block each. | No. |
| 390 | `source_id == target_id && return Int64[source_id]` | `&&` used as an early return. | `if (source_id == target_id)` / `return Int64[source_id]` / `end` | No. |
| 398 | `isnothing(parent) && return Int64[]` | `&&` used as an early return. | `if (isnothing(parent) == true)` / `return Int64[]` / `end` | No. |
| 435 | `path::AbstractVector{<:Integer}` | `<:` inside a type parameter ("any integer type") is unfamiliar. | `path::Array{Int64,1}` | Type: a `Vector{Int32}` or a range such as `1:3` would no longer be accepted (`MethodError`). The course passes `Vector{Int64}` from `reconstruct_path`. |
| 438 | `length(path) <= 1 && return 0.0` | `&&` used as an early return. | `if (length(path) <= 1)` / `return 0.0` / `end` | No. |
| 442 | `weights = Dict((edge.source, edge.target) => edge.weight for edge in edges)` | A dictionary comprehension with tuple keys. | `weights = Dict{Tuple{Int64,Int64}, Float64}()`, then `for edge in edges` / `weights[(edge.source, edge.target)] = edge.weight` / `end` | No. A repeated pair keeps the last weight in both forms. |
| 448 | `haskey(weights, key) \|\| throw(ArgumentError(...))` | `\|\|` used as control flow. | `if (haskey(weights, key) == false)` / `throw(ArgumentError(...))` / `end` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/Solvers.jl

Line numbers refer to the commented file.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 88, 170, 252, 351 | `A::AbstractMatrix{T}, b::AbstractVector{T}, xₒ::AbstractVector{T}; ...) where T <: Number` | Type parameters and `where`. The hidden rule that all three share one element type gives a `MethodError` for an integer `A` with a `Float64` `b`. | `A::AbstractMatrix{<:Number}, b::AbstractVector{<:Number}, xₒ::AbstractVector{<:Number}` with no `where` clause. | Types only: mixed element types would now be accepted instead of raising a `MethodError`. The archive is `Float64` either way. |
| 97, 178, 260 | `if (any(diag(A) .== 0.0))` | Broadcast comparison inside `any`. | `for i ∈ 1:size(A, 1) if (A[i,i] == 0.0) error("..."); end end` | No. Same message. |
| 100, 122 | `D = Diagonal(diag(A));` ... `d = D \ r;` | A special matrix type and the backslash operator for what is a division per row. | `diagonal = diag(A);` then `d = r ./ diagonal;`, the same form as the L6d lab's `my_jacobi`. | No. Each entry is the same single division. |
| 104, 185, 269 | `while true` with three `return` statements inside | The loop condition says nothing; the exits are hidden in an if-chain. | Follow the L6c pseudocode: `converged = false; while (converged == false) ... end`, set a flag in each branch, and one `return archive` after the loop. | No, if the three tests keep their order. |
| 123, 204, 288 | `k += 1;` | Compound assignment. | `k = k + 1;` | No. |
| 181, 203 | `C = LowerTriangular(A);` ... `d = C \ r;` | Backslash with a triangular type hides forward substitution. | Comments enough. An explicit forward-substitution loop would be longer and could change the last digits through a different summation order. | Only if replaced by a loop (rounding). |
| 264, 265, 287 | `L = tril(A,-1); C = LowerTriangular(D + ω*L); d = ω * (C \ r);` | The `-1` offset argument, and the factor `ω` outside the solve. | Comments enough. | — |
| 356 | `maxiterations >= 0 \|\| throw(ArgumentError("maxiterations must be nonnegative"));` | Short-circuit `\|\| throw` one-liner, which the instructor has objected to. | `if (maxiterations < 0) throw(ArgumentError("maxiterations must be nonnegative")); end` | No. |
| 361 | `return _solve(A, b, xₒ, algorithm, ϵ = ϵ, maxiterations = maxiterations, ω = ω);` | Keyword arguments passed after a comma look like positional arguments; the choice of method by the type of `algorithm` (dispatch) is invisible. | `archive = _solve(A, b, xₒ, algorithm; ϵ = ϵ, maxiterations = maxiterations, ω = ω); return archive;` | No. |
| 420 | `@variable(model, lb[i,1] <= x[i=1:d] <= ub[i,1], start=0.0)` | JuMP container syntax binds `i` inside the macro; `lb[i,1]` uses two indices on a vector. | `@variable(model, lb[i] <= x[i = 1:d] <= ub[i], start = 0.0)` | No. `lb` and `ub` are typed as vectors in the model. |
| 423 | `@objective(model, Max, transpose(c)*x);` | `transpose` for a dot product; the model type also allows `c` to be a `d × 1` matrix, which would make this a 1-element vector. | Comments enough. | — |
| 428-444 | `@constraints(model, begin A*x <= b end);` (three times) | The plural macro with a `begin ... end` block, for one vector constraint. | `@constraint(model, A*x <= b);` (and `>=`, `==` in the other branches). | No. Same constraints. |
| 454 | `@assert is_solved_and_feasible(model)` | `@assert` as a run-time check; the error message is generic and does not say what the solver reported. | `if (is_solved_and_feasible(model) == false) throw(ErrorException("the solver did not find an optimal, feasible solution: $(termination_status(model))")); end` | Yes: `ErrorException` with a clearer message instead of `AssertionError`. The L5c example text that mentions the `@assert` statement would need an update. |
| 457 | `x_opt = value.(x);` | Broadcast dot on a function call. | `x_opt = zeros(d); for i ∈ 1:d x_opt[i] = value(x[i]); end` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/StacksQueues.jl

Line numbers refer to the commented file. Nothing below has been applied.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 73, 109 | `MyStack{T}() where {T} = MyStack{T}(Vector{T}())` (and the `MyQueue` version) | A one-line outer constructor with a `where {T}` type parameter. | `function MyStack{T}() where {T}` / `items = Array{T,1}()` / `return MyStack{T}(items)` / `end`. The `where {T}` must stay, because the caller chooses `T`. | No. |
| 133, 206 | `Base.push!(stack::MyStack, value) = (push!(stack.items, value); stack)` (and the `MyQueue` version) | A one-line method whose body is a parenthesized block `(a; b)` that returns its last value. | `function Base.push!(stack::MyStack, value)` / `push!(stack.items, value)` / `return stack` / `end` | No. |
| 149, 165, 178, 191, 222, 238, 251, 264 | One-line method definitions such as `Base.pop!(stack::MyStack) = pop!(stack.items)` | The short `f(x) = ...` form plus `Base.` to extend a built-in function. | `function Base.pop!(stack::MyStack)` / `return pop!(stack.items)` / `end`, and the same for each method. | No. The `Base.` prefix must stay so that `push!`, `pop!`, and the others keep working on the new types. |
| 284 | `_isopener(character::Char)::Bool = character in ('(', '[', '{')` | A one-line function with a return type, testing membership in a tuple of characters. | `function _isopener(character::Char)::Bool` / `return (character == '(' \|\| character == '[' \|\| character == '{')` / `end` | No. |
| 329 | `isempty(pending) && return false` | `&&` used as an early return. | `if (isempty(pending) == true)` / `return false` / `end` | No. |
| 332 | `pop!(pending) == _OPENER_FOR_CLOSER[character] \|\| return false` | A `pop!` that changes the stack sits inside a test, and `\|\|` is used as an early return. | `opener = pop!(pending)`, then `if (opener != _OPENER_FOR_CLOSER[character])` / `return false` / `end` | No. |

Verdict: rewrite recommended.

## Syntax audit: code/src/TextRepresentation.jl

Line numbers refer to the commented file.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 46 | `hexadecimal = uppercase(string(UInt32(character); base = 16, pad = 4))` | Three calls nested in one line, read from the inside out, with keyword arguments after a `;` in the middle call. | `code_point = UInt32(character);` then `hexadecimal_lowercase = string(code_point; base = 16, pad = 4);` then `hexadecimal = uppercase(hexadecimal_lowercase);` | No. |
| 50 | `return "U+$(hexadecimal)"` | String interpolation with `$( )`. The L2c lecture uses it elsewhere, so this one is familiar by then. | `return "U+" * hexadecimal;` (Julia joins strings with `*`). | No. |

Verdict: rewrite recommended (line 46 only; line 50 is fine with its comment).

## Syntax audit: code/src/Types.jl

Line numbers refer to the commented file. Types.jl holds only type definitions, so it has none of the
function-body constructs on the instructor's list (no `|| throw`, ternaries, generators, `do` blocks,
closures, or `(; a, b)`). The hard parts are type-declaration syntax, which the new header and the
docstrings now explain.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 514, 517, 552 | `data::Union{Nothing, Any}` and `weight::Union{Nothing, Any}` | `Union{Nothing, Any}` looks like a restriction, but it is exactly `Any`, because `nothing` is already an `Any`. The original comment "this is a little fancy??" shows the confusion. | `data::Any` and `weight::Any` (and `data::Any` in the constructor signature). | No. `Union{Nothing, Any} === Any`, so the types, dispatch, and printing stay the same. |
| 324, 367, 413, 447, 486, 555, 600, 645, 679, 739, 928, 972, 1046, 1072, 1098, 1123, 1162, 1206, 1252, 1296, 1334, 1367, 1411 | `Name() = new()` (inner constructor with no arguments) | `new` exists only inside a struct definition, and `new()` with no arguments leaves every field unset. Reading an unset field gives an `UndefRefError` for arrays and dictionaries, or a meaningless number for `Int64`/`Float64` fields. | No rewrite: the whole `build(...)` pattern in Factory.jl depends on it. Each one now has a one-line comment, and the header explains the pattern. | A rewrite would change how every model is built. |
| 517 | `MyGraphNodeModel(id::Int64, data::Union{Nothing, Any}) = new(id, data);` | This is the only struct with a two-argument constructor and no `build` method, so it breaks the pattern of every other type. | Keep it, or replace it with `MyGraphNodeModel() = new();` plus a `build(MyGraphNodeModel, (id = ..., data = ...))` method. | Yes for the second option: Factory.jl calls `MyGraphNodeModel(id, nothing)` in two places and would need the same change. Comments are enough. |
| 1328–1330, 1362–1363 | `Array{<:Number, 2}`, `Array{<:Number, 1}` | `<:` inside braces means "some subtype of Number", which is new syntax at the point where students also meet `<:` for families. | Comments are enough (the header now defines it). A concrete type such as `Array{Float32,2}` would be simpler to read. | Yes for a concrete type: build stores `Float32` in `W` but the memories may be `Int32`; a fixed type could reject current inputs. |
| 921–924, 1157–1158, 1363 | Unicode field names `𝒮`, `𝒜`, `nₒ`, `μₒ`, `X̂` | Students must know the tab-completion codes (`\scrS`, `\scrA`, `\_o`, `\hat`) to type `m.𝒮` or `context.nₒ`. | No rewrite: notebooks use `build(MyMDPProblemModel, (𝒮 = 𝒮, ...))` and `m.𝒮`. Comments are enough. | Yes: renaming a field breaks every notebook and file that reads it. |
| 923–924 | `T::Union{Function, Array{Float64,3}}`, `R::Union{Function, Array{Float64,2}}` | The type says a function is allowed, but `lookahead`, `Q`, `backup`, and `solve` in MDP.jl index `T[s, s′, a]` and `R[s, a]` with brackets, so a function fails later with a confusing error. | Comments are enough (the docstring now says the array is required). A stricter rewrite is `T::Array{Float64,3}` and `R::Array{Float64,2}`. | Yes for the stricter rewrite: anyone who passes a function would now get an error at `build`. No course notebook passes one. |
| 319 | `c::Union{Array{Float64,2}, Array{Float64,1}}` | A union of a vector and a matrix for one list of coefficients. | Comments are enough. | Changing it to `Array{Float64,1}` could reject what L5c passes as `c = u`; not checked. |
| 274 | `abstract type AbstractlHopfieldNetworkModel end` | The name has a stray `l` ("Abstractl"), so students who type `AbstractHopfieldNetworkModel` get an `UndefVarError`. | `abstract type AbstractHopfieldNetworkModel end` plus `const AbstractlHopfieldNetworkModel = AbstractHopfieldNetworkModel` to keep the old name working, and export both. | Printing changes: the type prints under the new name. Code that uses the old name keeps working through the alias. |
| 589 | `mutable struct MyConstrainedGraphEdgeModel` (no `<: AbstractGraphEdgeModel`) | Every other model declares a family. The odd one out makes students wonder whether the omission matters. | `mutable struct MyConstrainedGraphEdgeModel <: AbstractGraphEdgeModel`. | Its supertype changes from `Any` to `AbstractGraphEdgeModel`. No function in the package dispatches on `AbstractGraphEdgeModel`, so no current call changes. |
| 993 | `struct MyValueIterationModel` (immutable, no `new()`, no `build`) | It is created with `MyValueIterationModel(1000)`, unlike every other model, which uses `build(...)`. The old docstring also claimed `<: AbstractProcessModel`, which the code does not declare (now fixed in the docstring). | Comments are enough. | Changing it to the `build` pattern breaks `MyValueIterationModel(1000)` in L11d and L12a. |
| 758–875 | `struct DijkstraAlgorithm <: AbstractGraphSearchAlgorithm end` (one-line empty structs) | A struct with no fields, created with `DijkstraAlgorithm()`, whose only job is to select a method, is a new idea. | Comments are enough: each tag now has a docstring and a group comment above it. | n/a |
| 363–364, 404–410, 514, 552, 595, 996, 1364 | Trailing `;` after field declarations, e.g., `β::Vector{Float64};` | Inconsistent with the other structs; a beginner may think the semicolon means something. | Drop the semicolons. | No: the parser ignores them. |

Verdict: comments enough.

## Syntax audit: code/src/VLDataScienceMachineLearningPackage.jl

Line numbers refer to the commented file. The module file has no functions, so it has none of the
function-body constructs on the instructor's list. The only nested call is on line 22.

| Line | Construct | Why it is hard for a beginner | Plain rewrite | Could the rewrite change behavior? |
|---|---|---|---|---|
| 22 | `const _PATH_TO_SRC = dirname(pathof(@__MODULE__));` | A nested call around a macro: `@__MODULE__` (the current module), `pathof(...)` (the path of its file), and `dirname(...)` (the folder) on one line. | Two named steps: `const _PATH_TO_THIS_FILE = pathof(@__MODULE__); # the full path of this file` then `const _PATH_TO_SRC = dirname(_PATH_TO_THIS_FILE); # the folder that holds it`. | No: the same folder results. It adds one unexported constant. |
| 85–86 and 120–121 | `export MyEnglishLanguageVocabularyModel;` and `export MyMNISTHandwrittenDigitImageDataset;` appear twice, the second time under "Concrete types" | Students reading the export list think these are types, and wonder why they are listed twice. Both are dataset functions in Files.jl. | Delete lines 120–121 (and their new comment on line 119). | No: exporting a name twice has the same effect as exporting it once. |
| 124 | `export MyGraphNodeModel, MyGraphEdgeModel, MyGraphEdgeModels, ... , MyConstrainedGraphEdgeModels;` | One line mixes types (`MyGraphEdgeModel`) with functions whose names differ by one letter (`MyGraphEdgeModels`, the edge-file reader in Files.jl). | One name per line, with the two reader functions moved next to the dataset loaders. | No: export order has no effect. |
| 19 | Comment `(single definition for the merged package; see Decision 5 of the merge plan)` | Points to a merge plan that students cannot see. | Keep the new plain-English lines below it, and drop the reference to the plan if the instructor agrees. I left the original line in place. | No (comment only). |

Verdict: comments enough.
