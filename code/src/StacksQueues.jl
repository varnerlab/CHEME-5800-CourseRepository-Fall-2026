# ------------------------------------------------------------------------------------------------ #
# StacksQueues.jl
#
# Teaching implementations of the two access disciplines from the week-03 L3b lecture:
# `MyStack` is last-in-first-out and `MyQueue` is first-in-first-out, each backed by an
# ordinary `Vector` held in a private `items` field.
#
# The `My` prefix follows the package convention for course-authored types, and keeps these
# distinct from the `Stack` and `Queue` that DataStructures.jl exports, which the package
# also loads. `isbalanced` is the delimiter checker the lecture builds on `MyStack`.
# ------------------------------------------------------------------------------------------------ #

"""
    MyStack{T}

Last-in-first-out container backed by a `Vector{T}`. Interact with a stack only
through `push!`, `pop!`, `peek`, `isempty`, and `length`; the `items` field is
internal, private by convention, and may change without notice.
"""
struct MyStack{T}
    items::Vector{T}
end
MyStack{T}() where {T} = MyStack{T}(Vector{T}())

"""
    MyQueue{T}

First-in-first-out container backed by a `Vector{T}`. Interact with a queue only
through `push!`, `popfirst!`, `peek`, `isempty`, and `length`; the `items` field
is internal, private by convention, and may change without notice.
"""
struct MyQueue{T}
    items::Vector{T}
end
MyQueue{T}() where {T} = MyQueue{T}(Vector{T}())

# The public interface of each type is the set of Base functions extended below.
# No supported operation removes from the front of a `MyStack` or the back of a
# `MyQueue`. Julia does not hide fields, so `items` stays reachable; the interface
# marks it off-limits by convention, the way a leading underscore marks a helper.
Base.push!(stack::MyStack, value) = (push!(stack.items, value); stack)
Base.pop!(stack::MyStack) = pop!(stack.items)
Base.peek(stack::MyStack) = last(stack.items)
Base.isempty(stack::MyStack) = isempty(stack.items)
Base.length(stack::MyStack) = length(stack.items)

Base.push!(queue::MyQueue, value) = (push!(queue.items, value); queue)
Base.popfirst!(queue::MyQueue) = popfirst!(queue.items)
Base.peek(queue::MyQueue) = first(queue.items)
Base.isempty(queue::MyQueue) = isempty(queue.items)
Base.length(queue::MyQueue) = length(queue.items)

# Which opener matches each closer is private knowledge of the checker: callers
# ask whether text is balanced, never which delimiters the checker recognizes.
const _OPENER_FOR_CLOSER = Dict(')' => '(', ']' => '[', '}' => '{')

_isopener(character::Char)::Bool = character in ('(', '[', '{')

"""
    isbalanced(text::AbstractString) -> Bool

Return `true` when every `()`, `[]`, and `{}` delimiter in `text` closes in
last-opened-first-closed order, and `false` otherwise. Characters that are not
delimiters are ignored. The checker reads raw characters, so a delimiter inside
a quoted string or a comment counts like any other; a parser-grade check would
strip those regions first.
"""
function isbalanced(text::AbstractString)::Bool
    pending = MyStack{Char}()
    for character in text
        if _isopener(character)
            push!(pending, character)
        elseif haskey(_OPENER_FOR_CLOSER, character)
            isempty(pending) && return false
            pop!(pending) == _OPENER_FOR_CLOSER[character] || return false
        end
    end
    return isempty(pending)
end
