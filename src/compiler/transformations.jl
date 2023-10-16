function parse_transformation(ex, env, err::Vector{String}, debug::Dict)
    # First substitute known constants...
    ex = substitute_constants(ex, env, err, debug)
    if ex.head != :call
        push!(err, "Unknown transformation head $(ex.head)")
    end


    op = ex.args[1]

    if op == :exp
        inner = parse_transformation(ex.args[2], env, err, debug)
        inner === nothing && return nothing
        return (ComposedFunction(exp, inner[1]), inner[2])
    elseif op == :log
        inner = parse_transformation(ex.args[2], env, err, debug)
        inner === nothing && return nothing
        return (ComposedFunction(log, inner[1]), inner[2])
    elseif op == :abs
        inner = parse_transformation(ex.args[2], env, err, debug)
        inner === nothing && return nothing
        return (ComposedFunction(abs, inner[1]), inner[2])
    elseif op == :sqrt
        inner = parse_transformation(ex.args[2], env, err, debug)
        inner === nothing && return nothing
        return (ComposedFunction(sqrt, inner[1]), inner[2])
    elseif op in [:+, :*]
        args = ex.args[2:end]
        terms = [parse_transformation(arg, env, err, debug) for arg in args]

        if any(term -> term === nothing, terms)
            push!(err, "Error parsing transformation $(ex)")
            return nothing
        end

        # Only one term may have a variable
        if count(term -> term[2] !== nothing, terms) > 1
            push!(err, "Sum cannot have more than one variable term $(ex)")
            return nothing
        end

        println("Hmmm")
        var = filter(term -> term[2] !== nothing, terms)[1]

        # Ensure remaining terms are all constants
        consts = filter(terms) do term
            return (term[2] === nothing && term[1] isa Real)
        end
        consts = map(term -> term[1], consts)
        if length(consts) != length(terms) - 1
            push!(err, "Sum cannot have more than one variable term $(ex)")
            return nothing
        end

        if op == :+
            c = sum(consts)
            f = ComposedFunction(AdditiveTransform(c), var[1])
        else
            c = prod(consts)
            f = ComposedFunction(MultiplicativeTransform(c), var[1])
        end
        return (f, var[2])

        # display(terms)
    else
        push!(err, "Unknown transformation $(op)")
        return 
    end

    if get(debug, DEBUG_TRANSFORM, false)
        dump(ex)
    end

end


function parse_transformation(ex::Symbol, env, err::Vector{String}, debug::Dict)
    # verify that symbol is a variable in scope
    if !hasvariable(env, ex)
        push!(err, "Variable $(ex) not in scope")
        return nothing
    end

    return identity, ex
end

function parse_transformation(ex::Real, env, err::Vector{String}, debug::Dict)
    return (ex,nothing)
end