const CONSTANT = :as1fdvesef
function parse_transformation(formula::Num, err::Vector{String}, debug::Dict)
    if length(Symbolics.get_variables(formula)) != 1
        push!(err, "Transformation must have exactly one random variable.")
        return 
    end

    parse_transformation(Symbolics.toexpr(formula), err, debug)
end

function parse_transformation(ex::Expr, err::Vector{String}, debug::Dict)
    if ex.head != :call
        push!(err, "Unknown transformation head $(ex)")
        return
    end

    op = ex.args[1]
    if get(debug, DEBUG_TRANSFORM, false)
        println("TRANSFORM: $(ex)")
    end

    if op == exp || op == log || op == abs || op == sqrt
        inner = parse_transformation(ex.args[2], err, debug)
        inner === nothing && return nothing
        return (ComposedFunction(op, inner[1]), inner[2])
    elseif op == ^
        inner = parse_transformation(ex.args[2], err, debug)
        inner === nothing && return nothing
        exponent = parse_transformation(ex.args[3], err, debug)
        exponent === nothing && return nothing
        if !isa(exponent[1], ConstantTransformation)
            push!(err, "Exponent not a constant: $(exponent[2])")
        end
        return PowerTransform(exponent[1]) ∘ inner[1], inner[2]
        # Check if exponent is constant
    elseif (op == +) || (op == *) || (op == /)
        left, _ = parse_transformation(ex.args[2], err, debug)
        right, right_var = parse_transformation(ex.args[3], err, debug)

        # One branch is a constant. The other is a variable.
        if !isa(left, ConstantTransformation)
            push!(err, "Expected constant on left side of $(ex)")
            return 
        end

        if op == +
            f = AdditiveTransform(left.a) ∘ right
        elseif op == *
            f = MultiplicativeTransform(left.a) ∘ right
        else
            f = ReciprocalTransform(left.a) ∘ right

        end

        return (f, right_var)
    elseif op == /

    end

    return
end

function parse_transformation(ex::Symbol, err::Vector{String}, debug::Dict)
    return identity, ex
end

function parse_transformation(ex::Real, err::Vector{String}, debug::Dict)
    return ConstantTransformation(ex),CONSTANT
end

function parse_transformation(ex, err::Vector{String}, debug::Dict)
    push!(err, "Unknown transformation $(ex)")
    return
end
