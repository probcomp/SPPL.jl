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
Skip = ast_compiler.Skip
Sample = ast_compiler.Sample
Transform = ast_compiler.Transform
Cond = ast_compiler.Condition
IfElse = ast_compiler.IfElse
For = ast_compiler.For
Switch = ast_compiler.Switch
Sequence = ast_compiler.Sequence

# Distributions.
Atomic = dists.atomic
Choice = dists.NominalDistribution
Bernoulli = dists.bernoulli

function _sppl(expr::Expr)
    commands = Any[]
    @assert expr.head == :block
    for ex in expr.args
        new = MacroTools.postwalk(ex) do e
            if @capture(e, v_ ~ d_)
                Expr(:call, GlobalRef(SPPL, :Sample), QuoteNode(v), d)
            elseif @capture(e, v_ == d_)
                Expr(:call, GlobalRef(SPPL, :Cond), QuoteNode(v), d)
            elseif @capture(e, if cond_ body1_ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, body1)
            elseif @capture(e, if cond_ body1_ else body2_ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, body1, cond, body2)
            else
                e
            end
        end
        push!(commands, new)
    end
    MacroTools.postwalk(rmlines ∘ unblock, Expr(:call, :Sequence, Expr(:vect, commands...)))
end

macro sppl(expr)
    new = _sppl(expr)
    display(new)
    new
end

macro sppl_str(str)
    nmspace = compiler(str).execute_module()
    nmspace.model
end

export @sppl, @sppl_str

end # module
