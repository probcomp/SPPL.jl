module SPPL

# A wrapper package (using `PythonCall.jl`) to `sppl`.

using MacroTools
using MacroTools: @capture, rmlines, unblock
using PythonCall

const fractions = PythonCall.pynew()
const sppl = PythonCall.pynew()
const dists = PythonCall.pynew()
const ast_compiler = PythonCall.pynew()
const sppl_compiler = PythonCall.pynew()
const transforms = PythonCall.pynew()
const sym_util = PythonCall.pynew()
const dnf = PythonCall.pynew()
const compiler = PythonCall.pynew()
const Id = PythonCall.pynew()
const IdArray = PythonCall.pynew()
const Skip = PythonCall.pynew()
const Sample = PythonCall.pynew()
const Transform = PythonCall.pynew()
const Cond = PythonCall.pynew()
const IfElse = PythonCall.pynew()
const For = PythonCall.pynew()
const SSwitch = PythonCall.pynew()
const Sequence = PythonCall.pynew()
const dnf_to_disjoint_union = PythonCall.pynew()
const binspace = PythonCall.pynew()
const Fraction = PythonCall.pynew()
const Sqrt = PythonCall.pynew()

function __init__()
    PythonCall.pycopy!(fractions, pyimport("fractions"))
    PythonCall.pycopy!(sppl, pyimport("sppl"))
    PythonCall.pycopy!(dists, pyimport("sppl.distributions"))
    PythonCall.pycopy!(ast_compiler, 
                       pyimport("sppl.compilers.ast_to_spe"))
    PythonCall.pycopy!(sppl_compiler, 
                       pyimport("sppl.compilers.sppl_to_python"))
    PythonCall.pycopy!(transforms, pyimport("sppl.transforms"))
    PythonCall.pycopy!(sym_util, pyimport("sppl.sym_util"))
    PythonCall.pycopy!(dnf, pyimport("sppl.dnf"))
    PythonCall.pycopy!(compiler, sppl_compiler.SPPL_Compiler)
    PythonCall.pycopy!(Id, ast_compiler.Id)
    PythonCall.pycopy!(IdArray, ast_compiler.IdArray)
    PythonCall.pycopy!(Skip, ast_compiler.Skip)
    PythonCall.pycopy!(Sample, ast_compiler.Sample)
    PythonCall.pycopy!(Transform, ast_compiler.Transform)
    PythonCall.pycopy!(Cond, ast_compiler.Condition)
    PythonCall.pycopy!(IfElse, ast_compiler.IfElse)
    PythonCall.pycopy!(For, ast_compiler.For)
    PythonCall.pycopy!(SSwitch, ast_compiler.Switch)
    PythonCall.pycopy!(Sequence, ast_compiler.Sequence)
    PythonCall.pycopy!(dnf_to_disjoint_union, dnf.dnf_to_disjoint_union)
    PythonCall.pycopy!(binspace, sym_util.binspace)
    PythonCall.pycopy!(Fraction, fractions.Fraction)
    PythonCall.pycopy!(Sqrt, transforms.Sqrt)
end

export fractions, sppl, dists, ast_compiler, sppl_compiler, transforms, sym_util, dnf, compiler
export Id, IdArray, Skip, Sample, Transform, Cond, IfElse, For, Switch, Sequence

function Switch(fn::Function, y, enumeration)
    return SSwitch(y, enumeration, fn)
end

const array = IdArray
export array

set(s::Symbol) = pyset([string(s)])
set(s) = pyset([s]); export set

export dnf_to_disjoint_union
export binspace, Fraction, Sqrt

#####
##### Distributions
#####

Atomic(loc) = dists.atomic(loc = loc)
Choice(d) = dists.NominalDistribution(pydict(d))
Choice(d::Vector) = dists.NominalDistribution(pydict(d))
function Choice(d::Vector{Pair{Symbol, T}}) where T
    d = map(d) do (k, v)
        (string(k), v)
    end
    dists.NominalDistribution(pydict(d))
end
Uniform(loc, scale) = dists.uniform(loc = loc, scale = scale)
Bernoulli(p) = dists.bernoulli(p = p)
Poisson(μ) = dists.poisson(mu = μ)
TruncatedNormal(a, b) = dists.truncnorm(a = a, b = b)
Normal(loc, scale) = dists.norm(loc = loc, scale = scale)
Normal() = dists.norm()
Binomial(n, p) = dists.binomial(n = n, p = p)
DiscreteUniform(values) = dists.uniformd(values = values)
RandInt(low, high) = dists.randint(low = low, high = high)
Beta(a, b) = dists.beta(a = a, b = b)
DiscreteLaplace(loc, a) = dists.dlaplace(loc = loc, a = a)
Gamma(loc, a) = dists.gamma(loc = loc, a = a)

export Atomic
export Choice
export Uniform
export Bernoulli
export Poisson
export TruncatedNormal
export Normal
export Binomial
export DiscreteUniform
export RandInt
export Beta
export DiscreteLaplace
export Gamma

#####
##### Accessor utility calls
#####

mutual_information(model::Py, cond1::Py, cond2::Py) = model.mutual_information(cond1, cond2)
condition(model::Py, cond::Py) = model.condition(cond)
probability(model::Py, cond::Py) = model.prob(cond)

export condition, probability, mutual_information

#####
##### Macros
#####

function id(x::Symbol)
    return Id(string(x))
end

function parse_block(expr::Expr)
    commands = Any[]
    array_declarations = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    for ex in expr.args
        new = MacroTools.postwalk(ex) do e

            if @capture(e, v_[a_] ~ d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Sample), 
                         quote $v[$a] end, d)

            elseif @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ = array(n_))
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n)))
                end
                e = Expr(:noop)

            elseif @capture(e, v_[a_] .> d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Transform), quote $v[$a] end, d)

            elseif @capture(e, v_ .> d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Transform), v, d)

            elseif @capture(e, v_ == d_)
                Expr(:call, :(<<), v, Expr(:call, GlobalRef(SPPL, :set), d))

            elseif @capture(e, if cond_ body1__ else body2__ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            elseif @capture(e, for ind_ in stx_ : endx_ body_ end)
                # Note: the endx + 1 gives for loops Julia bound inclusion semantics.
                Expr(:call, GlobalRef(SPPL, :For), 
                     stx, 
                     Expr(:call, +, endx, 1),
                     Expr(:->, ind, body)) 

            elseif @capture(e, cond_ ? body1__ : body2__)
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

    # Filter commands to remove :noop expressions caused by array declarations exprs (see this part of the conditional matching above).
    commands = filter(commands) do expr
        expr isa Expr && expr.head != :noop
    end

    # Organize body into a Sequence - return a namespace.
    emit = Expr(:block, values(variable_declarations)...,
                Expr(:(=), :command, Expr(:call, GlobalRef(SPPL, :Sequence), commands...)),
                quote model = command.interpret() end,
                Expr(:(=), :namespace, Expr(:tuple, namespace..., Expr(:(=), :model, :model))),
                quote namespace end)

    emit = MacroTools.postwalk(rmlines ∘ unblock, emit)
    emit
end

function parse_longdef_function(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    @capture(expr, function fn_(args__) body__ end) || error("ParseError (parse_function): parsing took invalid branch (syntax match failure).")
    for ex in body
        new = MacroTools.postwalk(ex) do e

            if @capture(e, v_[a_] ~ d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Sample), quote $v[$a] end, d)

            elseif @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ = array(n_))
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n)))
                end
                e = Expr(:noop)

            elseif @capture(e, v_[a_] .> d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Transform), quote $v[$a] end, d)

            elseif @capture(e, v_ .> d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Transform), v, d)

            elseif @capture(e, v_ == d_)
                Expr(:call, :(<<), v, Expr(:call, GlobalRef(SPPL, :set), d))

            elseif @capture(e, if cond_ body1__ else body2__ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            elseif @capture(e, for ind_ in stx_ : endx_ body_ end)
                Expr(:call, GlobalRef(SPPL, :For), stx, endx, Expr(:->, ind, body)) 

            elseif @capture(e, cond_ ? body1__ : body2__)
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
    
    # Filter commands to remove :noop expressions caused by array declarations exprs (see this part of the conditional matching above).
    commands = filter(commands) do expr
        expr isa Expr && expr.head != :noop
    end

    # Transformed body of method.
    new_body = Expr(:block, values(variable_declarations)...,
                    Expr(:(=), :command, Expr(:call, GlobalRef(SPPL, :Sequence), commands...)),
                    quote model = command.interpret() end,
                    Expr(:(=), :namespace, Expr(:tuple, namespace..., Expr(:(=), :model, :model))),
                    quote namespace end)

    emit = quote function $fn($(args...))
            $new_body
        end
    end
    MacroTools.postwalk(rmlines ∘ unblock, emit)
end

function parse_anonymous_function(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    @capture(expr, (args__) -> body__) || error("ParseError (parse_anonymous_function): parsing took invalid branch (syntax match failure).")
    for ex in body
        new = MacroTools.postwalk(ex) do e

            if @capture(e, v_[a_] ~ d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Sample), quote $v[$a] end, d)

            elseif @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ = array(n_))
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n)))
                end
                e = Expr(:noop)

            elseif @capture(e, v_[a_] .> d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Transform), quote $v[$a] end, d)

            elseif @capture(e, v_ .> d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Transform), v, d)

            elseif @capture(e, v_ == d_)
                Expr(:call, :(<<), v, Expr(:call, GlobalRef(SPPL, :set), d))

            elseif @capture(e, if cond_ body1__ else body2__ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            elseif @capture(e, for ind_ in stx_ : endx_ body_ end)
                Expr(:call, GlobalRef(SPPL, :For), stx, endx, Expr(:->, ind, body)) 

            elseif @capture(e, cond_ ? body1__ : body2__)
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

    # Transformed body of method.
    new_body = Expr(:block, values(variable_declarations)...,
                    Expr(:(=), :command, Expr(:call, GlobalRef(SPPL, :Sequence), commands...)),
                    quote model = command.interpret() end,
                    Expr(:(=), :namespace, Expr(:tuple, namespace..., Expr(:(=), :model, :model))),
                    quote namespace end)

    emit = Expr(:->, Expr(:tuple, args...), new_body)
    MacroTools.postwalk(rmlines ∘ unblock, emit)
end

function _sppl(expr::Expr)
    expr.head == :block && return parse_block(expr)
    expr.head == :function && return parse_longdef_function(expr)
    expr.head == :-> && return parse_anonymous_function(expr)
    if expr.head == :(=)
        longdef = MacroTools.longdef(expr)
        longdef.head == :function && return parse_longdef_function(longdef)
    end
    error("ParseError (@sppl): requires a block, a longdef function definition, a shortdef function definition, or an anonymous function definition.")
end

macro sppl(expr)
    new = _sppl(expr)
    esc(new)
end

macro sppl(debug, expr)
    new = _sppl(expr)
    debug == :debug && println(new)
    esc(new)
end

# String macro.
macro sppl_str(debug_flag, str)
    comp = compiler(str)
    debug_flag == :debug && println(comp.render_module())
    comp.execute_module()
end

macro sppl_str(str)
    compiler(str).execute_module()
end

export @sppl, @sppl_str

end # module
