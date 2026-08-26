"""Defensive Fibonacci implementation used by the optional Python section."""


def fibonacci_sequence(n: int) -> list[int]:
    """Return ``[F_0, F_1, ..., F_n]`` for an integer index from 0 through 92.

    Args:
        n: Largest Fibonacci index to compute. Boolean values are rejected even
            though ``bool`` is a subclass of ``int`` in Python.

    Returns:
        A list containing the Fibonacci values from ``F_0`` through ``F_n``.

    Raises:
        TypeError: If ``n`` is not an integer or is a Boolean.
        ValueError: If ``n`` is outside the supported range from 0 through 92.
    """

    # Check the exact input type so that True and False are not treated as the
    # integer indices 1 and 0.
    if type(n) is not int:
        raise TypeError("n must be an integer index")

    # Apply the same numerical limits as the Julia Int64 interface. Python
    # integers can grow beyond this range, but the shared contract stops at 92.
    if n < 0:
        raise ValueError("n must be nonnegative")
    if n > 92:
        raise ValueError("n must be at most 92 for Int64-compatible output")

    # Start with F_0. The n == 0 case is complete and returns before F_1 is
    # appended.
    sequence = [0]
    if n == 0:
        return sequence

    # Store F_1, then compute each remaining value from the two preceding values.
    sequence.append(1)
    for _index in range(2, n + 1):
        sequence.append(sequence[-1] + sequence[-2])

    return sequence
