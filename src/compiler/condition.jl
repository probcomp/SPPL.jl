macro condition(ex)
    return quote
        parse_query($(QuoteNode(ex)))
    end
end

parse_query(ex) =  parse_query(ex, String[], Dict{DebugFlag, Bool}())
function parse_query(ex, env, err::Vector{String}, debug::Dict)
    sub_ex = substitute_constants(ex, env, err, debug)
    parse_query(sub_ex, err, debug)
end

function parse_query(ex, err::Vector{String}, debug::Dict)
    if ex.head == :call
        op = ex.args[1]
        if op == :!
        elseif op == :<
        elseif op == :>
        elseif op == :<=
        elseif op == :>=
        elseif op == :(==)
        elseif op == :!=
        end

    elseif ex.head == :comparison
        operands = ex.args[1:2:end]
        print(operands)
    elseif ex.head == :&&
        left = parse_transformation(ex, err, debug)
        right = parse_transformation(ex, err, debug)
    elseif ex.head == :||
        left = parse_query(ex, err, debug)
        right = parse_query(ex, err, debug)
    else
        push!(err, "Unknown query type $(ex.head)")
    end
end

export @condition