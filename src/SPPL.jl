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

function parse_block(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    for ex in expr.args
        new = MacroTools.postwalk(ex) do e
            if @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ == d_)

                # Convert to set.
                str = "{$d}"
                s = py"set([$str])"

                quote $v << $s end

            elseif @capture(e, if cond_ body1_ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, body1)

            elseif @capture(e, if cond_ body1__ else body2__ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            else
                e

            end
        end
        push!(commands, new)
    end

    emit = Expr(:block, values(variable_declarations)...,
                Expr(:(=), :command, Expr(:call, :Sequence, commands...)),
                quote model = command.interpret() end)
    MacroTools.postwalk(rmlines ∘ unblock, emit)
end

function parse_function(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    @capture(expr, function fn_(args__) body__ end)
    for ex in expr.args
        new = MacroTools.postwalk(ex) do e
            if @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ == d_)

                # Convert to set.
                str = "{$d}"
                s = py"set([$str])"

                quote $v << $s end

            elseif @capture(e, if cond_ body1_ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, body1)

            elseif @capture(e, if cond_ body1__ else body2__ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            else
                e

            end
        end
        push!(commands, new)
    end

    new_body = Expr(:block, values(variable_declarations)...,
                    Expr(:(=), :command, Expr(:call, :Sequence, commands...)),
                    quote model = command.interpret() end,
                    quote model end)

    emit = quote function $fn($(args...))
            $new_body
        end
    end
    MacroTools.postwalk(rmlines ∘ unblock, emit)
end

function _sppl(expr::Expr)
    expr.head == :block && return parse_block(expr)
    expr.head == :function && return parse_function(expr)
    error("ParseError (@sppl): requires a block or a long-form function definition.")
end

macro sppl(expr)
    new = _sppl(expr)
    display(new)
    new
end

macro sppl_str(str)
    compiler(str).execute_module().model
end

export @sppl, @sppl_str

end # module
