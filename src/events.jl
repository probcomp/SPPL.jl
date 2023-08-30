abstract type Event end

(e::Event)(assignment::Dict) = assignment in e

abstract type BasicEvent <: Event end
struct SolvedEvent{T<:SPPLSet} <: BasicEvent
    symbol::Symbol
    predicate::T
end

function Base.in(assignment::Dict{Symbol,T}, e::SolvedEvent) where {T}
    !(e.symbol in keys(assignment)) && error("Error: Cannot evaluate event. Symbol $(e.symbol) not defined")
    assignment[e.symbol] in e.predicate
end

struct UnsolvedEvent{T,F} <: BasicEvent
    symbol::Symbol
    predicate::T
    transform::F
end

function Base.in(assignment::Dict{Symbol,T}, event::UnsolvedEvent) where {T}
    !(event.symbol in keys(assignment)) && error("Error: Cannot evaluate event. Symbol $(event.symbol) not defined")
    event.transform(assignment[event.symbol]) in event.predicate
end

struct AndEvent{T} <: Event
    events::T
    is_dnf::Bool
end
AndEvent(events) = AndEvent(events, false)

Base.in(assignment::Dict{Symbol,T}, e::AndEvent) where {T} = all(x -> x(assignment), e.events)

struct OrEvent{T} <: Event
    events::T
    is_dnf::Bool
end
OrEvent(events) = OrEvent(events, false)

(e::OrEvent)(assignment::Dict) = any(x -> x(assignment), e.events)
Base.in(assignment::Dict{Symbol,T}, e::OrEvent) where {T} = any(x -> x(assignment), e.events)

#############
# Inversion
#############
function preimage(e::SolvedEvent, b::Bool)
    b && return Dict(e.symbol => e.predicate)
    return Dict(e.symbol => complement(e.predicate))
end

function preimage(event::UnsolvedEvent, b::Bool)
    e = b ? event.predicate : complement(event.predicate) # TODO: Type unstable.
    I = preimage(event.transform, e)
    return Dict(event.symbol => I)
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


Base.union(x::Event, y::Event) = union(y, x)
Base.union(x::BasicEvent, y::BasicEvent) = OrEvent((x, y))
Base.union(x::OrEvent, y::OrEvent) = OrEvent(tuple(x.events..., y.events...))
Base.union(x::OrEvent, y::Union{AndEvent,BasicEvent}) = OrEvent(tuple(x.events..., y))
Base.union(x::AndEvent, y::AndEvent) = OrEvent((x, y))
Base.union(x::AndEvent, y::BasicEvent) = OrEvent((x, y))

distribute(x::Event, y::Event) = distribute(y, x)
distribute(x::BasicEvent, y::BasicEvent) = AndEvent((x, y))
distribute(x::BasicEvent, y::AndEvent) = AndEvent(tuple(y.events, x))
distribute(x::AndEvent, y::AndEvent) = AndEvent(tuple(x.events..., y.events...))
function distribute(x::AndEvent, y::OrEvent)
    clauses = map(v -> AndEvent((x.events..., v)), y.events)
    OrEvent(clauses)
end
function distribute(x::OrEvent, y::OrEvent)
    clauses = map(v -> distribute(v[1], v[2]), Iterators.product(x.events, y.events))
    OrEvent(tuple(clauses...))
end
##################
# Normalization
##################
# length(symbols(event)) > 1 && error("cannot solve multi-symbol event")
solve(event::SolvedEvent) = event
function solve(event::UnsolvedEvent)
    space = preimage(event, true)[event.symbol]
    BasicEvent(event.symbol, space)
end
dnf(event::BasicEvent) = event
function dnf(event::AndEvent)
    reduce(distribute, dnf.(event.events))
end
function dnf(event::OrEvent)
    reduce(union, dnf.(event.events))
end

function dnf_factor(event)
    error("Not yet implemented")
end


function dnf_non_disjoint_clauses(event)
    error("Not yet implemented")
end

function dnf_to_disjoint_union(event)
    error("Not yet implemented")
end

#########
# Show
#########
function Base.show(io::IO, m::MIME"text/plain", x::SolvedEvent)
    print(io, "$(x.symbol)∈")
    show(io, m, x.predicate)
end
function Base.show(io::IO, m::MIME"text/plain", x::UnsolvedEvent{T,<:ComposedFunction{A,B}}) where {T,A,B}
    print(io, "($(x.transform))($(x.symbol))∈")
    show(io, m, x.predicate)
end
function Base.show(io::IO, m::MIME"text/plain", x::UnsolvedEvent)
    print(io, "$(x.transform)($(x.symbol))∈")
    show(io, m, x.predicate)
end
function Base.show(io::IO, m::MIME"text/plain", x::AndEvent)
    events = x.events
    for i = 1:length(events)
        clause = events[i]
        if !(clause isa BasicEvent)
            print(io, "(")
        end
        show(io, m, clause)
        if !(clause isa BasicEvent)
            print(io, ")")
        end
        if i < length(events)
            print(io, " ∧ ") # \wedge
        end
    end
end

function Base.show(io::IO, m::MIME"text/plain", x::OrEvent)
    events = x.events
    for i = 1:length(events)
        clause = events[i]
        if !(clause isa BasicEvent)
            print(io, "(")
        end
        show(io, m, clause)
        if !(clause isa BasicEvent)
            print(io, ")")
        end
        if i < length(events)
            print(io, " ∨ ") # \vee
        end
    end
end

export AndEvent, OrEvent, SolvedEvent, UnsolvedEvent
export solve, dnf, distribute
