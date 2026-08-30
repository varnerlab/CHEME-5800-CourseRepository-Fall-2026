# Sound support for the L3d sorting lab. This file is included from inside the
# L3dSorting module by both the student stub and the reference solution, so the
# playback helper is available to `bubblesort!` under either file.
import WAV

"""
    load_sound_library(directory::AbstractString;
        number_of_samples::Int64 = 128) -> Dict{Int64, Tuple{Matrix{Float64}, Float32}}

Read the tone files `example-1.wav` through `example-(number_of_samples).wav`
from `directory` and return a dictionary mapping the integer value `k` to the
waveform and sampling frequency of its tone. Sorting an integer array drawn
from `1:number_of_samples` with this dictionary supplied plays one tone per
element, so each bubble-sort pass is audible.
"""
function load_sound_library(directory::AbstractString;
    number_of_samples::Int64 = 128)::Dict{Int64, Tuple{Matrix{Float64}, Float32}}

    library = Dict{Int64, Tuple{Matrix{Float64}, Float32}}()
    for index in 1:number_of_samples
        waveform, sampling_frequency = WAV.wavread(joinpath(directory, "example-$(index).wav"))
        library[index] = (waveform, Float32(sampling_frequency))
    end
    return library
end

# Play one tone per element, in array order. Private: callers hear the sounds
# by passing a library to `bubblesort!`, never by calling this directly. The
# Task wrapper works around playback flakiness in WAV.wavplay observed in the
# Fall 2024 version of this lab.
function _play_sound(values::AbstractVector{<:Number};
    sounds::Union{Nothing, Dict{Int64, Tuple{Matrix{Float64}, Float32}}} = nothing)::Nothing

    sounds === nothing && return nothing
    for value in values
        waveform, sampling_frequency = sounds[Int(value)]
        playback = Task(() -> WAV.wavplay(waveform, sampling_frequency))
        schedule(playback)
        wait(playback)
    end
    return nothing
end
