using MacroTools
using Symbolics

include("objects.jl")
include("transformations.jl")
include("condition.jl")
include("sppl_to_spe.jl")

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


function compile(ex)
    debug = Dict{DebugFlag, Bool}()
    compile(ex, debug)
end

function compile(ex, debug) 
    env = Environment()
    errors = String[]
    parse_block(ex, env, errors, debug)
    if length(errors) > 0
        throw(errors)
    end
    return Program(env, errors)
end

function parse_block(ex, env, err::Vector{String}, debug=false)
    for statement in ex.args
        parse_statement(statement, env, err, debug)
    end
    return env
end

function parse_statement(ex::LineNumberNode, env, err::Vector{String}, debug=false)
    if get(debug, DEBUG_LINE_NUMBER, false)
        dump(ex)
    end
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

    if haskey(env, lvalue)
        push!(err, "Cannot reassign constant $(lvalue)")
        return
    end
    if hasvariable(env, lvalue)
        push!(err, "Cannot reassign variable $(lvalue)")
        return
    end
    # Evaluate constant using previous constants.
    sub_ex = substitute_constants(ex.args[2], env, err, debug)
    env.constants[lvalue] = eval(sub_ex)
end


function parse_call(ex, env, err::Vector{String}, debug=false)
    op = ex.args[1]
    if op == :~
        return parse_sample(ex, env, err, debug)
    elseif op == :Condition
        return parse_condition(ex, env, err, debug)
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

    if haskey(env, lvalue)
        push!(err, "Cannot reassign constant $(lvalue)")
    end
    if hasvariable(env, lvalue)
        push!(err, "Cannot reassign variable $(lvalue)")
    end
    var_name = (@variables $(lvalue))[1]
    env.variables[lvalue] = (var_name, dist)
    return
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
        args = [substitute_constants(arg, env, err, debug) for arg in ex.args[2:end]]
        dist_args = eval.(args)
        dist = eval(dist_type)
        return dist(dist_args...)
    else
        sub_ex = substitute_locals(ex, env, err, debug)

        # Do some exception handling here
        sub_ex = eval(sub_ex)
        sub_ex = simplify(sub_ex, rewriter = SIMPLIFICATION_RULES)

        try
            transform = parse_transformation(sub_ex, err, debug)
            if transform === nothing
                push!(err, "Could not interpret transform $(ex)")
                return nothing
            end

            if !hasvariable(env, transform[2]) # TODO: Consider moving this before parsing?
                push!(err, "Variable $(transform[2]) not in scope")
                return nothing
            end
            return transform
        catch e
            push!(err, string(e))
            return
        end
    end
end

function parse_distribution(ex::Real, env, err::Vector{String}, debug::Dict)
    throw("TODO: Atomic not defined for distributions.")
    # This is an atomic? Transform into a constant.
    return ex
end

function is_base_dist(dist)
    try
        eval(dist) <: Distributions.UnivariateDistribution
    catch
        return false
    end
end

function parse_do_block(ex, env, err, debug=false)
    if !expect_call(ex.args[1], :Switch)
        push!(err, "Expected Switch Statement $(ex.args[1])")
        return 
    end

    lvalue, cases = parse_switch_signature(ex.args[1], env, err, debug)
    if !hasvariable(env, lvalue)
        push!(err, "Variable $(lvalue) not defined")
        return
    end

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


function substitute_locals(ex, env, err::Vector{String}, debug::Dict)
    sub_ex = MacroTools.postwalk(sub_(env), ex)
    if get(debug, DEBUG_SUBSTITUTE, false)
        println("Constant: ", ex, " -> ", sub_ex)
    end
    sub_ex
end

function substitute_constants(ex, env, err::Vector{String}, debug)
    sub_ex = MacroTools.postwalk(sub_func(env), ex)
    if get(debug, DEBUG_SUBSTITUTE, false)
        println("Constant: ", ex, " -> ", sub_ex)
    end
    return sub_ex
end

function sub_(env::Environment)
    function substitute(ex)
        if haskey(env, ex) # Defined as a constant
            return env[ex]
        elseif hasvariable(env, ex) # Defined as a variable
            return getvariable(env, ex)[1]
        else
            return ex
        end

    end
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
    dump(cond)
    dump(block)
    if length(ex.args) == 2
        # parse condition
        # if only
    end

    if length(ex.args) == 3
        rest = ex.args[3]
        println("Rest")
        dump(rest)
        if rest.head == :block # just else?
        end

        if rest.head == :ifelse # elseif block

        end
    end
end

function parse_condition(ex, env, err::Vector{String}, debug::Dict)
    query = ex.args[2]
    if get(debug, DEBUG_CONDITION, false)
        println("Condition $(ex)")
    end
    parse_query(query, env, err, debug)
end


expect_call(ex, name::Symbol) = (ex.head == :call && ex.args[1] == name)

export @sppl

# Debug Flags
@enum DebugFlag begin
    DEBUG_LINE_NUMBER
    DEBUG_SAMPLE
    DEBUG_ASSIGNMENT
    DEBUG_SUBSTITUTE
    DEBUG_TRANSFORM
    DEBUG_CONDITION
end

const SIMPLIFICATION_RULES = Symbolics.Chain([
    @rule log(exp(~x)) => ~x
    @acrule log(exp(~x))+~y => ~x+~y

    @rule sqrt((~x)^2) => abs(~x)
    @acrule sqrt((~x)^2)+~y => abs(~x)+~y
])