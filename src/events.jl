abstract type Event end

abstract type BasicEvent <: Event end
(e::Event)(assignment::Dict) = assignment in e

struct SolvedEvent{T<:SPPLSet} <: BasicEvent
    symbol::Symbol
    predicate::T
end

function Base.in(assignment::Dict{Symbol,T}, e::SolvedEvent) where {T}
    !(e.symbol in keys(assignment)) && error("Error: Cannot evaluate event. Symbol $(e.symbol) not defined")
    assignment[e.symbol] in e.predicate
end

struct UnsolvedEvent{T<:SPPLSet} <: BasicEvent
    symbol::Symbol
    predicate::T
    transform
end

struct AndEvent{T} <: Event
    events::T
end

Base.in(assignment::Dict{Symbol,T}, e::AndEvent) where {T} = all(x -> x(assignment), e.events)

struct OrEvent{T} <: Event
    events::T
end

(e::OrEvent)(assignment::Dict) = any(x -> x(assignment), e.events)
Base.in(assignment::Dict{Symbol,T}, e::OrEvent) where {T} = any(x -> x(assignment), e.events)

#############
# Inversion
#############
function preimage(e::SolvedEvent, b)
    if b == 0
        # println(e.predicate)
        return e.symbol => complement(e.predicate)
    elseif b == 1
        return e.symbol => e.predicate
    end
    return e.symbol => EMPTY_SET
end

function preimage(e::UnsolvedEvent, b)
    I = preimage(e.transform, b == 0 ? complement(e.predicate) : e.predicate)
    return e.symbol => I
end

function preimage(e::AndEvent, b)
    regions = preimage.(e.events, Ref(b))
    print(regions)
end
##################
# Normalization
##################

function dnf(event::Event)

end

function dnf_factor(event)
end


function dnf_non_disjoint_clauses(event)
end

function dnf_to_disjoint_union(event)
end
export AndEvent, OrEvent, SolvedEvent, UnsolvedEvent
