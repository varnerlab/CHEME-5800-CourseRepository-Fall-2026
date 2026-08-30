# L3d sound library

The 128 files `example-1.wav` through `example-128.wav` are short instructor-generated
tones, one per integer value, rising in pitch with the value. They carry over from the
Fall 2024 CHEME 4800/5800 bubble-sort discussion lab and contain no experimental or
recorded content.

The lab's `load_sound_library` function reads the whole set into a dictionary keyed by
integer value. Passing that dictionary to `bubblesort!` while sorting an integer array
drawn from `1:128` plays the array as a tone sequence at the top of every pass, so a
shuffled array sounds jumbled and a sorted one plays a rising scale. The library is
optional: every function in the lab runs silently when no dictionary is supplied, which
is also how the validation suite runs.

The whole set is about 520 KB and ships with the student bundle.
