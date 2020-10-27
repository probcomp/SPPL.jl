module SPPL

using PyCall
using Conda
using MacroTools
using MacroTools: @capture, rmlines, unblock

# Install ProbLog.
if PyCall.conda
    Conda.add("pip")
    pip = joinpath(Conda.BINDIR, "pip")
    run(`$pip install sppl`)
else
    try
        pyimport("sppl")
        pyimport("sppl.compilers")
    catch ee
        typeof(ee) <: PyCall.PyError || rethrow(ee)
        warn("""
             Python Dependencies not installed
             Please either:
             - Rebuild PyCall to use Conda, by running in the julia REPL:
             - `ENV[PYTHON]=""; Pkg.build("PyCall"); Pkg.build("Problox")`
             - Or install the depencences, eg by running pip
             - `pip install sppl`
             """
             )
    end
end

sppl = pyimport("sppl")
dists = pyimport("sppl.distributions")
ast_compiler = pyimport("sppl.compilers.ast_to_spn")
sppl_compiler = pyimport("sppl.compilers.sppl_to_python")
compiler = sppl_compiler.SPPL_Compiler

# Commands.
Id = ast_compiler.Id
IdArray = ast_compiler.IdArray
Skip = ast_compiler.Skip
Sample = ast_compiler.Sample
Transform = ast_compiler.Transform
Cond = ast_compiler.Condition
IfElse = ast_compiler.IfElse
For = ast_compiler.For
Switch = ast_compiler.Switch
Sequence = ast_compiler.Sequence

# Distributions.
Atomic(loc) = dists.atomic(loc=loc)
Choice(d) = dists.NominalDistribution(Dict(d))
Uniform(loc, scale) = dists.uniform(loc=loc, scale=scale)
Bernoulli(p) = dists.bernoulli(p=p)

set(s) = py"{$s}"
export set

include("dsl.jl")
export @sppl, @sppl_str

end # module
