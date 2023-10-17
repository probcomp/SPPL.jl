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
    # Here it is assumed that all unspecified variales are random variables???
    if ex.head == :call
        op = ex.args[1]
        if op == :! || 
            op == :> || 
            op == :< || 
            op == :>= || 
            op == :(==) || 
            op == :(!=)
            event = parse_comp(ex, Val(op), err, debug)
        else
            push!(err, "Unknown query type $(ex.head)")
            return 
        end

    elseif ex.head == :comparison
        operands = ex.args[1:2:end]
        print(operands)
    elseif ex.head == :&&
        left = parse_query(ex.args[1], err, debug)
        left === nothing && return nothing
        right = parse_query(ex.args[2], err, debug)
        right === nothing && return nothing

    elseif ex.head == :||
        left = parse_query(ex.args[1], err, debug)
        left === nothing && return nothing
        right = parse_query(ex.args[2], err, debug)
        right === nothing && return nothing

    else
        push!(err, "Unknown query type $(ex.head)")
    end
end

function parse_comp(ex, ::Val{:<}, err::Vector{String}, debug::Dict)

end

function parse_comp(ex, ::Val{:>}, err::Vector{String}, debug::Dict)
    left = parse_transformation(ex.args[2], err, debug)
    right = parse_transformation(ex.args[3], err, debug)
    left === nothing && return nothing
    right === nothing && return nothing
    # TODO: Assumes variables all on one side...

    
    # println(left)
    # println(right)
    # UnsolvedEvent()
end

function parse_comp(ex, ::Val{:>=}, err::Vector{String}, debug::Dict)

end

function parse_comp(ex, ::Val{:<=}, err::Vector{String}, debug::Dict)

end

function parse_comp(ex, ::Val{:(==)}, err::Vector{String}, debug::Dict)

end

function parse_comp(ex, ::Val{:(!=)}, err::Vector{String}, debug::Dict)

end




export @condition