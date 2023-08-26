module SPPL
using MacroTools
using Distributions
import Random: AbstractRNG
import Base: rand

include("utils.jl")
# println(@macroexpand @flip foo(x, y::Bool) = x)
include("intervals.jl")
include("transforms.jl")
include("events.jl")
include("spe.jl")
include("compiler/compiler.jl")
export @flip


end
