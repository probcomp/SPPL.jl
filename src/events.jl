abstract type Event end

struct EventBasic <: Event
end
struct AndEvent <: Event
    events::Vector{Event}
end

struct OrEvent <: Event
    events::Vector{Event}
end
simplify(event::Event) = 0

# Base.in(x, event::Event) = (x in event.events)
# Base.in(x::AbstractDict{Symbol,T}, event::Event) where {T} = event.symbol in keys(x) && x[event.symbol] in event.events

# function Base.in(x::AbstractDict{Symbol,T}, event::AndEvent) where {T}
#     for e in event.events
#         !(x in e) && return false
#     end
#     return true
# end

# function Base.in(x::AbstractDict{Symbol,T}, event::OrEvent) where {T}
#     for e in event.events
#         x in e && return true
#     end
#     return false
# end

export AndEvent, OrEvent
