using MacroTools
using Symbolics

include("objects.jl")

macro sppl(ex)
    ex = MacroTools.longdef(ex)
    quote
        compile($(QuoteNode(ex))) # add compile() call
    end
end
macro sppl(debug, ex)
    ex = MacroTools.longdef(ex)
    quote
        compile($(QuoteNode(ex)), $(esc(debug)))
    end
end


function compile(ex, debug) 
    env = Environment()
    errors = String[]
    parse_block(ex, env, errors, debug)
    # if debug
    #     return env, errors
    # else
    #     return env
    # end
    return Program(env, errors)
end
compile(ex, debug::Bool=false) = compile(ex, Dict{DebugFlag, Bool}())

function parse_block(ex, env, err::Vector{String}, debug=false)
    for statement in ex.args
        parse_statement(statement, env, err, debug)
    end
    return env
end

function parse_statement(ex::LineNumberNode, env, err::Vector{String}, debug=false)
    # if debug
    #     dump(ex)
    # end
    return
end

function parse_statement(ex, env, err::Vector{String}, debug=false)
    if ex.head == :(=)
        parse_assignment(ex, env, err, debug)
    elseif ex.head == :call 
        parse_call(ex, env, err, debug)
    elseif ex.head == :do
        parse_do_block(ex, env, err, debug)
    elseif ex.head == :if 
        parse_if_block(ex, env, err, debug)    
    else
        push!(err,  "Unknown statement type $(ex.head)")
    end
    return
end

function parse_assignment(ex, env, err, debug=false)
    lvalue = parse_lvalue(ex.args[1], err, env, debug)
    if lvalue === nothing
        return
    end

    if haskey(env.constants, lvalue)
        push!(err, "Cannot reassign constant $(lvalue)")
        return
    end
    # Evaluate constant using previous constants.
    sub_ex = parse_constant(ex.args[2], env, err, debug)
    env.constants[lvalue] = eval(sub_ex)
end


function parse_call(ex, env, err::Vector{String}, debug=false)
    op = ex.args[1]
    if op == :~
        return parse_sample(ex, env, err, debug)
    else
        push!(err, "Prefix operator $(op) not supported")
        return nothing
    end
end

function parse_sample(ex, env, err::Vector{String}, debug::Dict)
    lvalue = parse_lvalue(ex.args[2], env, err, debug)
    dist = parse_distribution(ex.args[3], env, err, debug)

    if haskey(debug, DEBUG_SAMPLE) && debug[DEBUG_SAMPLE]
        println("SAMPLE: ", lvalue, " ~ ", dist)
    end

    if haskey(env.variables, lvalue)
        push!(err, "Cannot reassign variable $(lvalue)")
    end
    env.variables[lvalue] = dist
    # ident = scan(ex.args[2])
    # right = scan(ex.args[3])

    # if !is_token(ident, :ident)
    #     throw("Sample identifier must be a symbol or array index")
    # end

    # assert ident is symbol or array index
    # assert right is distribution expression
    # create an ast
end

function parse_lvalue(ex, env, err, debug=false)
    if ex isa Symbol
        return ex
        # if haskey(program.constants, ident )
        #     push!(program.errors, "Cannot reassign constant $(ident)")
        #     return nothing
        # end
        # program.constants[ident] = eval(ex.args[2])
    else
        push!(err,  "Unknown identifier for assignment. Got $(ex.args[1])")
        return nothing
    end
end

function parse_distribution(ex, env, err::Vector{String}, debug::Dict)
    if ex.head != :call
        push!(err, "Unknown distribution expression")
        return nothing
    end

    dist_type = ex.args[1]

    if is_base_dist(dist_type)
        args = [parse_constant(arg, env, err, debug) for arg in ex.args[2:end]]
        dist_args = eval.(args)
        dist = eval(dist_type)
        return dist(dist_args...)
    elseif is_transform(ex, env, err, debug)

    else
        push!(err, "Unknown distribution type $(dist_type)")
        return
    end
end

function is_base_dist(dist)
    try
        eval(dist) <: Distributions.UnivariateDistribution
    catch
        return false
    end
end
function is_transform(ex, env, err, debug)
    sub_ex = parse_constant(ex, env, err, debug)
    # dump(sub_ex)
    sym = parse_expr_to_symbolic(sub_ex, @__MODULE__)
    display(sym)
    return false
    # if ex.head != :call
    #     return false
    # end
    # dist_type = ex.args[1]
    # if dist_type == :Transform
    #     return true
    # else
    #     return false
    # end
end

function parse_do_block(ex, env, err, debug=false)
    if !expect_call(ex.args[1], :Switch)
        push!(err, "Expected Switch Statement $(ex.args[1])")
        return 
    end

    lvalue, cases = parse_switch_signature(ex.args[1], env, err, debug)
    # TODO: LVALUE!!!
    for val in cases
        new_env = new_scope(env)
        parse_closure(ex.args[2], val, new_env, err, debug)
    end
end
function parse_switch_signature(ex, env, err::Vector{String}, debug=false)
    lvalue = parse_lvalue(ex.args[2], env, err, debug)
    cases = collect(eval(ex.args[3]))
    return lvalue, cases
end

function parse_closure(ex, val, env, err::Vector{String}, debug=false)
    func_args = ex.args[1].args
    if length(func_args) != 1
        push!(err, "Expected one argument to Switch closure")
    end
    var = func_args[1]
    if haskey(env, var)
        push!(err, "Cannot reassign variable $(var)")
    end

    env[var] = val
    parse_block(ex.args[2], env, err, debug)

    # println(env
end

function parse_transformation(ex, env, err, debug=false)
end

function parse_constant(ex, env, err::Vector{String}, debug)
    sub_ex = MacroTools.postwalk(sub_func(env), ex)
    if get(debug, DEBUG_CONSTANT, false)
        println("Constant: ", ex, " -> ", sub_ex)
    end
    return sub_ex
end

function sub_func(env::Environment)
    function substitute(ex)
        if ex isa Symbol 
            if haskey(env, ex)
                return env[ex]
            else
                return ex
            end
        else
            return ex
        end
    end
end

function parse_if_block(ex, env, err::Vector{String}, debug=false)
    cond = ex.args[1]
    block = ex.args[2]
    # dump(cond)
    # dump(block)
    # if length(ex.args) == 2
    #     # parse condition
    #     # if only
    # end

    # if length(ex.args) == 3
    #     rest = ex.args[3]
    #     println("Rest")
    #     dump(rest)
    #     if rest.head == :block # just else?
    #     end

    #     if rest.head == :ifelse # elseif block

    #     end
    # end
end



expect_call(ex, name::Symbol) = (ex.head == :call && ex.args[1] == name)

export @sppl

# Debug Flags
@enum DebugFlag begin
    DEBUG_SAMPLE
    DEBUG_ASSIGNMENT
    DEBUG_CONSTANT
    # DEBUG_PARSE
    # DEBUG_COMPILE
    # DEBUG_EVAL
end