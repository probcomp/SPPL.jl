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
    predicte::T
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

preimage(e::SolvedEvent) = Dict(e.symbol => e.predicate)

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
