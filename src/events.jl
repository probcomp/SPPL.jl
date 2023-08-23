using Intervals

abstract type Event end

struct TransformEvent{F<:Function,E<:Event} <: Event
    t::F
    event::E
end

struct RealFiniteEvent <: Event
end

struct RealRangeEvent <: Event
end

struct IntRangeEvent <: Event
end

struct IntFiniteEvent <: Event
    symbol::Symbol
    events::Set{Int}
end

struct StringEvent <: Event
    symbol::Symbol
    events::Set{String}
end

struct AndEvent <: Event
    events::Vector{Event}
end

struct OrEvent <: Event
    events::Vector{Event}
end

Base.in(x, event::Event) = (x in event.events)
Base.in(x::AbstractDict{Symbol,T}, event::Event) where {T} = event.symbol in keys(x) && x[event.symbol] in event.events

function Base.in(x::AbstractDict{Symbol,T}, event::AndEvent) where {T}
    for e in event.events
        !(x in e) && return false
    end
    return true
end

function Base.in(x::AbstractDict{Symbol,T}, event::OrEvent) where {T}
    for e in event.events
        x in e && return true
    end
    return false
end

# function dnf_normalize(event::Event)
# end

export RealEvent, IntEvent, StringEvent, AndEvent, OrEvent
