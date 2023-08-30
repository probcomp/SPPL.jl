abstract type Event end

function solve(event::Event)
    length(symbols(event)) > 1 && error("cannot solve multi-symbol event")
    preimage(event, true)
end
function to_dnf(event::Event)

end
abstract type BasicEvent <: Event end
(e::Event)(assignment::Dict) = assignment in e

struct SolvedEvent{T} <: BasicEvent
    symbol::Symbol
    predicate::T
end

function Base.in(assignment::Dict{Symbol,T}, e::SolvedEvent) where {T}
    !(e.symbol in keys(assignment)) && error("Error: Cannot evaluate event. Symbol $(e.symbol) not defined")
    assignment[e.symbol] in e.predicate
end

struct UnsolvedEvent{T} <: BasicEvent
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
function preimage(e::SolvedEvent, b::Bool)
    b && return Dict(e.symbol => e.predicate)
    return Dict(e.symbol => complement(e.predicate))
end

function preimage(e::UnsolvedEvent, b::Bool)
    I = preimage(e.transform, b == 0 ? complement(e.predicate) : e.predicate)
    return Dict(e.symbol => I)
end

function preimage(e::AndEvent, b::Bool)
    regions = preimage.(e.events, Ref(b))
    assignment = Dict{Symbol,Vector}()
    for r in regions
        for (symbol, event) in r
            if !(symbol in keys(assignment))
                assignment[symbol] = SPPLSet[]
            end
            push!(assignment[symbol], event)
        end
    end
    Dict(key => intersect(value...) for (key, value) in assignment)
end


function preimage(e::OrEvent, b::Bool)
    regions = preimage.(e.events, Ref(b))
    assignment = Dict{Symbol,Vector}()
    for r in regions
        for (symbol, event) in r
            if !(symbol in keys(assignment))
                assignment[symbol] = SPPLSet[]
            end
            push!(assignment[symbol], event)
        end
    end
    display(assignment[:x])
    Dict(key => union(value...) for (key, value) in assignment)
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
