module L3bStacksQueues

export Stack, Queue, isbalanced

"""
    Stack{T}

Last-in-first-out container backed by a `Vector{T}`. Interact with a stack only
through `push!`, `pop!`, `peek`, `isempty`, and `length`; the `items` field is
internal, private by convention, and may change without notice.
"""
struct Stack{T}
    items::Vector{T}
end
Stack{T}() where {T} = Stack{T}(Vector{T}())

"""
    Queue{T}

First-in-first-out container backed by a `Vector{T}`. Interact with a queue only
through `push!`, `popfirst!`, `peek`, `isempty`, and `length`; the `items` field
is internal, private by convention, and may change without notice.
"""
struct Queue{T}
    items::Vector{T}
end
Queue{T}() where {T} = Queue{T}(Vector{T}())

# The public interface of each type is the set of Base functions extended below.
# No supported operation removes from the front of a Stack or the back of a
# Queue. Julia does not hide fields, so `items` stays reachable; the interface
# marks it off-limits by convention, the way a leading underscore marks a helper.
Base.push!(stack::Stack, value) = (push!(stack.items, value); stack)
Base.pop!(stack::Stack) = pop!(stack.items)
Base.peek(stack::Stack) = last(stack.items)
Base.isempty(stack::Stack) = isempty(stack.items)
Base.length(stack::Stack) = length(stack.items)

Base.push!(queue::Queue, value) = (push!(queue.items, value); queue)
Base.popfirst!(queue::Queue) = popfirst!(queue.items)
Base.peek(queue::Queue) = first(queue.items)
Base.isempty(queue::Queue) = isempty(queue.items)
Base.length(queue::Queue) = length(queue.items)

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
    pending = Stack{Char}()
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

end
