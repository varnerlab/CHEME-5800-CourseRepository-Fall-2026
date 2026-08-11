# Local setup for CHEME 5800 L5c.

if !isdefined(@__MODULE__, :CHEME5800_L5C_ROOT)
    const CHEME5800_L5C_ROOT = @__DIR__
end

if !isdefined(@__MODULE__, :CHEME5800_L5C_FIGS)
    const CHEME5800_L5C_FIGS = joinpath(CHEME5800_L5C_ROOT, "figs")
end

include(normpath(joinpath(CHEME5800_L5C_ROOT, "..", "..", "..", "Include.jl")))

using DataFrames
using GLPK
using JuMP
using LinearAlgebra
using MathOptInterface
using Plots
using PrettyTables
using Test

if !isdefined(@__MODULE__, :L5cLinearPrograms)
    include(joinpath(CHEME5800_L5C_ROOT, "src", "LinearPrograms.jl"))
end

using .L5cLinearPrograms
