# ------------------------------------------------------------------------------------------------ #
# StacksQueues.jl
#
# Teaching implementations of the two access disciplines from the week-03 L3b lecture:
# `MyStack` is last-in-first-out and `MyQueue` is first-in-first-out, each backed by an
# ordinary `Vector` held in a private `items` field.
#
# - Last-in-first-out (LIFO): the item added most recently is the first item removed, like a
#   stack of plates.
# - First-in-first-out (FIFO): the item added first is the first item removed, like a checkout
#   line.
#
# The L3b lecture uses every public name below. The L4b lab uses `MyQueue` in its
# breadth-first search.
#
# Public types and functions:
#
#   MyStack{T}                 a LIFO stack that holds items of type T
#   MyQueue{T}                 a FIFO queue that holds items of type T
#   push!(stack, value)        adds value to the top of a stack
#   pop!(stack)                removes and returns the top item of a stack
#   push!(queue, value)        adds value to the back of a queue
#   popfirst!(queue)           removes and returns the front item of a queue
#   peek(stack) / peek(queue)  returns the next item to be removed, without removing it
#   isempty(...) / length(...) report whether a stack or queue is empty, and how many items it holds
#   isbalanced(text)           checks that the (), [], and {} delimiters in text close in order
#
# Private helpers (a leading underscore marks a name that callers should not use):
#
#   _OPENER_FOR_CLOSER         a dictionary that maps each closer, such as ')', to its opener, '('
#   _isopener(character)       checks whether a character is one of the openers (, [, or {
#
# The `My` prefix follows the package convention for course-authored types, and keeps these
# distinct from the `Stack` and `Queue` that DataStructures.jl exports, which the package
# also loads. `isbalanced` is the delimiter checker the lecture builds on `MyStack`.
# ------------------------------------------------------------------------------------------------ #

"""
    MyStack{T}

A last-in-first-out (LIFO) stack that holds items of type `T`. The item pushed most recently
is the first item removed. The stack stores its items in a `Vector{T}`, with the top of the
stack at the end of the vector.

Interact with a stack only through `push!`, `pop!`, `peek`, `isempty`, and `length`. The
`items` field is internal, private by convention, and may change without notice. Julia does
not hide fields, so a caller can still reach `items`; the rule is a convention.

### Fields
- `items::Vector{T}`: the stored items, oldest first. The last entry is the top of the stack.

### Constructors
- `MyStack{T}()`: an empty stack that will hold items of type `T`.
- `MyStack{T}(items::Vector{T})`: a stack that starts with the given items; the last entry is
  the top.

### Example
```julia
stack = MyStack{Char}();   # an empty stack of characters
push!(stack, 'a');
push!(stack, 'b');
peek(stack)                # 'b', the item pushed last
pop!(stack)                # removes and returns 'b'
length(stack)              # 1
```
"""
struct MyStack{T}
    items::Vector{T} # the stored items; the last entry is the top of the stack
end

# The outer constructor MyStack{T}() makes an empty stack. The `where {T}` part says that T
# is a type parameter: the caller picks it, e.g., MyStack{Char}() makes a stack of characters -
MyStack{T}() where {T} = MyStack{T}(Vector{T}())

"""
    MyQueue{T}

A first-in-first-out (FIFO) queue that holds items of type `T`. The item pushed first is the
first item removed. The queue stores its items in a `Vector{T}`, with the front of the queue
at the start of the vector and the back at the end.

Interact with a queue only through `push!`, `popfirst!`, `peek`, `isempty`, and `length`. The
`items` field is internal, private by convention, and may change without notice.

### Fields
- `items::Vector{T}`: the stored items in arrival order. The first entry is the front of the
  queue.

### Constructors
- `MyQueue{T}()`: an empty queue that will hold items of type `T`.
- `MyQueue{T}(items::Vector{T})`: a queue that starts with the given items; the first entry is
  the front.

### Example
```julia
queue = MyQueue{Char}();   # an empty queue of characters
push!(queue, 'a');
push!(queue, 'b');
peek(queue)                # 'a', the item pushed first
popfirst!(queue)           # removes and returns 'a'
length(queue)              # 1
```
"""
struct MyQueue{T}
    items::Vector{T} # the stored items in arrival order; the first entry is the front of the queue
end

# The outer constructor MyQueue{T}() makes an empty queue of items of type T -
MyQueue{T}() where {T} = MyQueue{T}(Vector{T}())

# The public interface of each type is the set of Base functions extended below.
# No supported operation removes from the front of a `MyStack` or the back of a
# `MyQueue`. Julia does not hide fields, so `items` stays reachable; the interface
# marks it off-limits by convention, the way a leading underscore marks a helper.
#
# Each method below is a one-line function definition: `f(x) = expression` defines a
# function f whose body is that single expression. Writing `Base.push!(...)` adds a new
# method to Julia's own push! function, so push! also works on our types.

"""
    push!(stack::MyStack, value) -> MyStack

Add `value` to the top of `stack`. The stack is changed in place.

### Arguments
- `stack::MyStack`: the stack to add to.
- `value`: the item to add. Julia converts it to the stack's item type `T`, and throws an
  error if it cannot.

### Returns
- `MyStack`: the same stack, now holding `value` on top.
"""
Base.push!(stack::MyStack, value) = (push!(stack.items, value); stack) # (a; b) runs a, then b, and gives the value of b: we add value to the end of the vector, then return the stack

"""
    pop!(stack::MyStack) -> T

Remove the top item of `stack` and return it. The stack is changed in place.

### Arguments
- `stack::MyStack`: the stack to remove from.

### Returns
- `T`: the item that was on top, i.e., the item pushed most recently.

### Throws
- `ArgumentError`: the stack is empty.
"""
Base.pop!(stack::MyStack) = pop!(stack.items) # the top of the stack is the last entry of the vector

"""
    peek(stack::MyStack) -> T

Return the top item of `stack` without removing it.

### Arguments
- `stack::MyStack`: the stack to look at.

### Returns
- `T`: the item that `pop!` would remove next.

### Throws
- `BoundsError`: the stack is empty.
"""
Base.peek(stack::MyStack) = last(stack.items) # the last entry of the vector is the top of the stack

"""
    isempty(stack::MyStack) -> Bool

Return `true` when `stack` holds no items, and `false` otherwise.

### Arguments
- `stack::MyStack`: the stack to check.

### Returns
- `Bool`: `true` for an empty stack.
"""
Base.isempty(stack::MyStack) = isempty(stack.items)

"""
    length(stack::MyStack) -> Int

Return the number of items in `stack`.

### Arguments
- `stack::MyStack`: the stack to count.

### Returns
- `Int`: the number of items the stack holds.
"""
Base.length(stack::MyStack) = length(stack.items)

"""
    push!(queue::MyQueue, value) -> MyQueue

Add `value` to the back of `queue`. The queue is changed in place.

### Arguments
- `queue::MyQueue`: the queue to add to.
- `value`: the item to add. Julia converts it to the queue's item type `T`, and throws an
  error if it cannot.

### Returns
- `MyQueue`: the same queue, now holding `value` at the back.
"""
Base.push!(queue::MyQueue, value) = (push!(queue.items, value); queue) # (a; b) runs a, then b, and gives the value of b: we add value to the end of the vector, then return the queue

"""
    popfirst!(queue::MyQueue) -> T

Remove the front item of `queue` and return it. The queue is changed in place.

### Arguments
- `queue::MyQueue`: the queue to remove from.

### Returns
- `T`: the item at the front, i.e., the oldest item in the queue.

### Throws
- `ArgumentError`: the queue is empty.
"""
Base.popfirst!(queue::MyQueue) = popfirst!(queue.items) # the front of the queue is the first entry of the vector

"""
    peek(queue::MyQueue) -> T

Return the front item of `queue` without removing it.

### Arguments
- `queue::MyQueue`: the queue to look at.

### Returns
- `T`: the item that `popfirst!` would remove next.

### Throws
- `BoundsError`: the queue is empty.
"""
Base.peek(queue::MyQueue) = first(queue.items) # the first entry of the vector is the front of the queue

"""
    isempty(queue::MyQueue) -> Bool

Return `true` when `queue` holds no items, and `false` otherwise.

### Arguments
- `queue::MyQueue`: the queue to check.

### Returns
- `Bool`: `true` for an empty queue.
"""
Base.isempty(queue::MyQueue) = isempty(queue.items)

"""
    length(queue::MyQueue) -> Int

Return the number of items in `queue`.

### Arguments
- `queue::MyQueue`: the queue to count.

### Returns
- `Int`: the number of items the queue holds.
"""
Base.length(queue::MyQueue) = length(queue.items)

# Which opener matches each closer is private knowledge of the checker: callers
# ask whether text is balanced, never which delimiters the checker recognizes.
# The dictionary maps each closer (the key) to the opener it must match (the value);
# `')' => '('` is a Pair, one key and its value -
const _OPENER_FOR_CLOSER = Dict(')' => '(', ']' => '[', '}' => '{')

"""
    _isopener(character::Char) -> Bool

Return `true` when `character` is one of the three openers `(`, `[`, or `{`, and `false`
otherwise. This helper is private to `isbalanced`.

### Arguments
- `character::Char`: the character to test.

### Returns
- `Bool`: `true` for `(`, `[`, or `{`, and `false` for every other character.
"""
_isopener(character::Char)::Bool = character in ('(', '[', '{') # `in` checks whether character is one of the three entries of the tuple

"""
    isbalanced(text::AbstractString) -> Bool

Return `true` when every `()`, `[]`, and `{}` delimiter in `text` closes in
last-opened-first-closed order, and `false` otherwise. Characters that are not
delimiters are ignored. The checker reads raw characters, so a delimiter inside
a quoted string or a comment counts like any other; a parser-grade check would
strip those regions first.

The method follows the L3b pseudocode. We read the text one character at a time and keep
the openers that are still open on a `MyStack`. An opener is pushed onto the stack. A closer
must match the opener on top of the stack, which is the most recently opened delimiter; we
pop that opener and compare. At the end of the text, the stack must be empty, because an
opener left on the stack was never closed.

### Arguments
- `text::AbstractString`: the text to check.

### Returns
- `Bool`: `true` when the delimiters are balanced, and `false` when a closer has no opener,
  a closer does not match the most recent opener, or an opener is never closed.

### Example
```julia
isbalanced("f(x[2]) + {a: (b)}")   # true
isbalanced("f(x[2)]")              # false: ')' cannot close the '[' opened last
```
"""
function isbalanced(text::AbstractString)::Bool

    # initialize: an empty stack holds the openers that are still open -
    pending = MyStack{Char}()

    # main loop: read the text one character at a time -
    for character in text
        if _isopener(character)

            # an opener: push it onto the stack -
            push!(pending, character)

        elseif haskey(_OPENER_FOR_CLOSER, character) # haskey is true when character is a closer, one of ), ], or }

            # a closer with nothing open: the text is not balanced -
            isempty(pending) && return false # if the stack is empty, stop and return false

            # pop the most recent opener; it must be the opener that matches this closer -
            pop!(pending) == _OPENER_FOR_CLOSER[character] || return false # if the popped opener does not match, stop and return false
        end
        # any other character is not a delimiter, so we ignore it
    end

    # the text is balanced only if no opener is left open -
    return isempty(pending)
end
