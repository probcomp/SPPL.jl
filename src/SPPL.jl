module SPPL
using MacroTools
using Distributions
import Random: AbstractRNG, default_rng, rand!
import Base: rand

include("utils.jl")
# println(@macroexpand @flip foo(x, y::Bool) = x)
include("intervals.jl")
include("transforms.jl")
include("events.jl")
include("spe.jl")
include("genericrand.jl")
include("compiler/compiler.jl")


end
