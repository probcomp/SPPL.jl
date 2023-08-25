abstract type Event end

struct SolvedEvent{T<:SPPLSet} <: Event
    symbol::Symbol
    predicate::T
end

function (e::SolvedEvent)(assignment::Dict{Symbol,T}) where {T}
    !(e.symbol in keys(assignment)) && error("Error: Cannot evaluate event. Symbol $(e.symbol) not defined")
    val = assignment[e.symbol]
    val in e.predicate
end

struct UnsolvedEvent{T<:SPPLSet} <: Event
    symbol::Symbol
    predicate::T
    environment::Dict{Symbol,Any}
end

struct AndEvent{T<:Event} <: Event
    events::Vector{T}
end

(e::AndEvent)(assignment::Dict) = all(x -> x(assignment), e.events)

struct OrEvent{T<:Event} <: Event
    events::Vector{T}
end

(e::OrEvent)(assignment::Dict) = any(x -> x(assignment), e.events)

#############
# Inversion
#############
function preimage(e::SolvedEvent, b)
    if b == 0
        return e.symbol => complement(e.predicate)
    elseif b == 1
        return e.symbol => e.predicate
    end
    return e.symbol => EMPTY_SET
end
function preimage(e::UnsolvedEvent, b)
    # if b == 0
    #     return
    # else
    #     return
    # end
    return e.symbol => EMPTY_SET
end

##################
# Normalization
##################

function dnf_factor(event)
end

function dnf_normalize(event::Event)

end

function dnf_non_disjoint_clauses(event)
end

function dnf_to_disjoint_union(event)
end
export AndEvent, OrEvent, SolvedEvent, UnsolvedEvent
