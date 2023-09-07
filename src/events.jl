abstract type Event end
abstract type BasicEvent <: Event end

struct SolvedEvent{T<:SPPLSet} <: BasicEvent
    symbol::Symbol
    predicate::T
end

struct UnsolvedEvent{T,F} <: BasicEvent
    symbol::Symbol
    predicate::T
    transform::F
end
symbol(e::BasicEvent) = e.symbol

struct AndEvent{E} <: Event
    events::Vector{E}
end
AndEvent(events) = AndEvent(events)
get_symbols(event::AndEvent) = [e.symbol for e in event.events]

struct OrEvent{T,U} <: Event 
    conjunctions::Vector{T}
    singletons::Vector{U}
end

#############
# Evaluation
#############
(e::Event)(assignment::Dict) = assignment in e

function Base.in(assignment::Dict{Symbol,T}, e::SolvedEvent) where {T}
    !(e.symbol in keys(assignment)) && error("Error: Cannot evaluate event. Symbol $(e.symbol) not defined")
    assignment[e.symbol] in e.predicate
end

function Base.in(assignment::Dict{Symbol,T}, event::UnsolvedEvent) where {T}
    !(event.symbol in keys(assignment)) && error("Error: Cannot evaluate event. Symbol $(event.symbol) not defined")
    event.transform(assignment[event.symbol]) in event.predicate
end

Base.in(assignment::Dict{Symbol,T}, e::AndEvent) where {T} = all(x -> x(assignment), e.events)
Base.in(assignment::Dict{Symbol,T}, e::OrEvent) where {T} = any(x -> x(assignment), e.events)

#############
# Preimage
#############

preimage(e::SolvedEvent) =  preimage(e, true)
function preimage(e::SolvedEvent, b::Bool)
    b && return Dict(e.symbol => e.predicate)
    return Dict(e.symbol => complement(e.predicate))
end

function preimage(event::UnsolvedEvent, b::Bool)
    e = b ? event.predicate : complement(event.predicate) # TODO: Type unstable.
    I = preimage(event.transform, e)
    return Dict(event.symbol => I)
end

function preimage(e::AndEvent, b::Bool) # Assumes DNF form?
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

###################
# Event Building
###################
Base.intersect(x::Event,y::Event) = intersect(y,x)
Base.intersect(x::UnsolvedEvent, y::Event) =  intersect(solve(x), y)
function Base.intersect(x::SolvedEvent, y::SolvedEvent)
    if x.symbol == y.symbol
        return SolvedEvent(x.symbol, intersect(x.predicate, y.predicate))
    end
    AndEvent([x,y])
end
function Base.intersect(x::SolvedEvent, y::AndEvent)
    symbols = get_symbols(y)
    if symbol(x) in symbols
        new_events = copy(y.events)
        i = findfirst(e->(symbol(e) == symbol(x)), new_events)
        new_events[i] = intersect(x, new_events[i])
        AndEvent(new_events)
    else
        return AndEvent(vcat(x, y.events))
    end
end
function Base.intersect(x::SolvedEvent, y::OrEvent) # TODO: Very type unstable. Because of list comprehension.
    conjunctions = [intersect(e,x) for e in y.conjunctions]
    singletons = [intersect(e,x) for e in y.singletons]
    # println(events)
    # OrEvent(map(v->intersect(x,v), y.events))
    OrEvent(conjunctions, singletons)
end
function Base.intersect(x::AndEvent, y::AndEvent)  # TODO: Type unstable.
    dict = SortedDict{Symbol, Any}()
    for e in x.events
        dict[e.symbol]  = e
    end
    for e in y.events
        if e.symbol in keys(dict)
            dict[e.symbol] = intersect(dict[e.symbol], e)
        else
            dict[e.symbol] = e
        end
    end
    AndEvent([e for e in values(dict)])
end

function Base.intersect(x::AndEvent, y::OrEvent) 
    clauses_1 = map(v->intersect(x,v), y.conjunctions)
    clauses_2 = map(v->intersect(x,v), y.singletons)
    OrEvent(vcat(clauses_1, clauses_2), SolvedEvent[])
end
function Base.intersect(x::OrEvent, y::OrEvent)
    clauses1 = vec(map(pair -> intersect(pair[1], pair[2]), Iterators.product(x.conjunctions, y.conjunctions)))
    clauses2 = vec(map(pair -> intersect(pair[1], pair[2]), Iterators.product(x.conjunctions, y.singletons)))
    clauses3 = vec(map(pair -> intersect(pair[1], pair[2]), Iterators.product(x.singletons, y.conjunctions)))
    clauses4 = vec(map(pair -> intersect(pair[1], pair[2]), Iterators.product(x.singletons, y.singletons)))
    OrEvent(vcat(clauses1, clauses2, clauses3, clauses4), SolvedEvent[])
end

Base.union(x::Event, y::Event) = union(y, x)
Base.union(x::UnsolvedEvent, y::Event) = union(solve(x), y)
function Base.union(x::SolvedEvent, y::SolvedEvent) 
    if x.symbol == y.symbol
        return SolvedEvent(x.symbol, union(x.predicate, y.predicate))
    end
    OrEvent(AndEvent[], [x, y])
end
Base.union(x::SolvedEvent, y::AndEvent) = OrEvent(y, x)
Base.union(x::SolvedEvent, y::OrEvent) = OrEvent(y.conjunctions, vcat(y.singletons, x))
Base.union(x::OrEvent, y::OrEvent) = OrEvent(vcat(x.conjunctions, y.conjunctions), vcat(x.singletons, y.singletons))
Base.union(x::OrEvent, y::AndEvent) = OrEvent(vcat(x.conjunctions,y), x.singletons)
Base.union(x::AndEvent, y::AndEvent) = OrEvent([x, y], SolvedEvent[])

complement(x::Event) = x
distribute(x::Event, y::Event) = x∩y 

#########################
# DNF and Simplification
#########################

solve(event::UnsolvedEvent) = SolvedEvent(event.symbol, preimage(event.transform, event.predicate))
dnf(event::BasicEvent) = event
dnf(event::UnsolvedEvent) = solve(event)

function dnf(event::AndEvent)
    reduce(distribute, dnf.(event.events))
end

function dnf(event::OrEvent)
    reduce(union, dnf.(event.events))
end

function simplify(event::AndEvent{T}) where T<:SolvedEvent
    symbols = SortedSet([e.symbol for e in event.events])
    SolvedEvent[]
end

# solved_dnf(event::OrEvent) = OrEvent(dnf_normalize.(event.events))
dnf_pie(event::SolvedEvent) = event
dnf_pie(event::AndEvent{<:SolvedEvent}) = event
function dnf_pie(event::OrEvent) 
    # if length(events.event) == 1
    #     return events.event[1]
    # end
    # C = events.event[1]
    # new_events = Event[events.event[1]]
    # for e in events.event[2:end]
    # end
end

###############
# Convenience
###############
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
    conjunctions = x.conjunctions
    singletons = x.singletons
    events = vcat(conjunctions, singletons)
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
export solve, dnf, simplify, distribute, symbols
