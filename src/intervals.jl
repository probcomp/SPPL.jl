import Base.union, Base.intersect
using OrderedCollections
using Intervals: Closed, Open
import Intervals: Intervals
using Logging

abstract type SPPLSet end
struct EmptySet <: SPPLSet end
const EMPTY_SET = EmptySet()

abstract type FiniteSet{T} <: SPPLSet end

struct FiniteNominal <: FiniteSet{String}
    members::OrderedSet{String}
    b::Bool
    function FiniteNominal(members::OrderedSet{String}, b::Bool)
        if length(members) == 0 && b
            return EMPTY_SET
        end
        new(members, b)
    end
end
function FiniteNominal(x...; b=true)
    if length(x) == 0
        return FiniteNominal(OrderedSet{String}(), b)
    end
    FiniteNominal(OrderedSet(x), b)
end
struct FiniteReal{T<:Real} <: FiniteSet{T}
    members::Set{T}
end
FiniteReal(x::Real...) = FiniteReal(Set(x))

#############
# Intervals
#############
abstract type Range <: SPPLSet end
struct Interval{T,U} <: Range # Wrapper around Intervals.jl
    a::T
    b::T
    left::Bool
    right::Bool
    interval::U
    function Interval(interval::Intervals.Interval{T,L,R}) where {T,L,R}
        if isempty(interval)
            return EMPTY_SET
        end
        left = L == Closed
        right = R == Closed
        new{T,typeof(interval)}(first(interval), last(interval), left, right, interval)
    end
    function Interval(a::T, b::T, left::Bool, right::Bool) where {T}
        L = left ? Closed : Open
        R = right ? Closed : Open
        interval = Intervals.Interval{L,R}(a, b)
        Interval(interval)
    end
end
Base.show(io::IO, x::Interval) = print(io, x.interval)
Base.:(==)(x::Interval, y::Interval) = x.interval == y.interval
Base.first(x::Interval) = first(x.interval)
Base.last(x::Interval) = last(x.interval)

struct IntervalSet{T} <: Range

end

#############
# Concat
#############
struct Concat{T<:Union{EmptySet,FiniteNominal},U<:Union{EmptySet,FiniteReal},V<:Union{EmptySet,Interval,IntervalSet}} <: SPPLSet
    nominal::T
    singleton::U
    intervals::V
    # function Concat(nominal::T, singleton::U, intervals::V) where {T,U,V}
    # count = 0
    # count += nominal == EMPTY_SET ? 0 : 1
    # count += singleton == EMPTY_SET ? 0 : 1
    # count += intervals == EMPTY_SET ? 0 : 1
    # if count == 0
    #     println("Hmmm")
    # elseif count == 1
    #     error("Concat should have two elements")
    # end
    # new{T,U,V}(nominal, singleton, intervals)
    # end
end
function Base.show(io::IO, x::Concat)
    print(io, "Concat($(x.nominal), $(x.singleton), $(x.intervals))")
end

#############
# Equality
#############
Base.:(==)(x::SPPLSet, y::SPPLSet) = false
Base.:(==)(::EmptySet, ::EmptySet) = true
Base.:(==)(x::FiniteNominal, y::FiniteNominal) = x.members == y.members && x.b == y.b
Base.:(==)(x::FiniteReal, y::FiniteReal) = x.members == y.members
Base.:(==)(x::Concat, y::Concat) = (x.nominal == y.nominal) && (x.singleton == y.singleton) && (x.intervals == y.intervals)

##########
# Invert
##########
# Not exactly complement, but convenient?
invert(x::FiniteNominal) = FiniteNominal(copy(x.members), !x.b) # TODO: Slow?
function invert(x::FiniteReal)
    intervals = intersect(invert.(x.members)...)
end
function invert(x::Intervals.Interval{T,L,R}) where {T,L,R}
    left = IntervalSet(Intervals.Interval{Closed,opposite(L)}(-Inf, first(x)))
    right = IntervalSet(Intervals.Interval{opposite(R),Closed}(last(x), Inf))
    int = union(left, right)
    intersect(int, int)
end
function invert(x::Real)
    left = Interval(Intervals.IntervalSet(Intervals.Interval{Closed,Open}(-Inf, x)))
    right = Interval(Intervals.IntervalSet(Intervals.Interval{Open,Closed}(x, Inf)))
    union(left, right)
end
function invert(x::IntervalSet{T}) where {T}
    arr = convert(Array{T}, x)
    new_arr = invert.(arr)
    intersect(new_arr...)
end
function invert(x::Interval)
    Interval(invert(x.interval))
end

#############
# Complement
#############

complement(::EmptySet) = Concat(FiniteNominal(; b=false), EMPTY_SET, Interval(Interval{Closed,Closed}(-Inf, Inf)))
complement(x::FiniteNominal) = Concat(invert(x), EMPTY_SET, IntervalSet(Interval{Closed,Closed}(-Inf, Inf)))
complement(x::FiniteReal) = Concat(invert(x), EMPTY_SET, IntervalSet(Interval{Closed,Cloesd}(-Inf, Inf)))
complement(x::Interval) = Concat(FiniteNominal(; b=false), EMPTY_SET, invert(x.interval))
function complement(x::Concat)
    set = x.nominal == EMPTY_SET ? FiniteNominal(OrderedSet{String}(); b=false) : invert(x.nominal)
    if x.singleton == EMPTY_SET
        return Concat(set, EMPTY_SET, invert(x.intervals))
    elseif x.intervals == EMPTY_SET
        return Concat(set, invert(x.singleton), EMPTY_SET)
    end
    union(set, intersect(x.singleton, x.intervals))
end

###############
# Intersection
###############
Base.intersect(x::SPPLSet, y::SPPLSet) = intersect(y, x)
Base.intersect(::EmptySet, y::SPPLSet) = EMPTY_SET
function Base.intersect(x::FiniteNominal, y::FiniteNominal)
    !xor(x.b, y.b) && return FiniteNominal(intersect(x.members, y.members), x.b)
    x.b && return FiniteNominal(OrderedSet(Iterators.filter(v -> v in y, x.members)), true) # TODO: Non-allocating version
    return FiniteNominal(OrderedSet(Iterators.filter(v -> v in x, y.members)), true)
end
Base.intersect(::FiniteNominal, ::FiniteReal) = EMPTY_SET
Base.intersect(::FiniteNominal, ::Interval) = EMPTY_SET
Base.intersect(x::FiniteReal, y::FiniteReal) = FiniteReal(intersect(x.members, y.members))
function Base.intersect(x::FiniteReal, y::Interval)
    members = filter(v -> v in y, x.members)
    return length(members) == 0 ? EMPTY_SET : FiniteReal(Set(members))
end
Base.intersect(x::Interval, y::Interval) = Interval(intersect(x.interval, y.interval))
Base.intersect(x::Concat, y::FiniteNominal) = intersect(x.nominal, y)
Base.intersect(x::Concat, y::FiniteReal) = union(intersect(x.singleton, y), intersect(x.intervals, y))
Base.intersect(x::Concat, y::Interval) = union(intersect(x.singleton, y), intersect(x.intervals, y))
function Base.intersect(x::Concat, y::Concat)
    nominals = intersect(x.nominal, y.nominal)
    singleton = intersect(x.singleton, y.singleton)
    intervals = intersect(x.intervals, y.intervals)
end
function Base.intersect(s::SPPLSet, itrs...)
    ans = s
    for x in itrs
        ans = intersect(ans, x)
    end
    return ans
end

##########
# Union
##########
Base.union(y::SPPLSet, x::SPPLSet) = union(x, y)
Base.union(::EmptySet, y::SPPLSet) = y
function Base.union(x::FiniteNominal, y::FiniteNominal)
    if !x.b
        members = filter(v -> !(v in y), x.members)
        return FiniteNominal(OrderedSet(members), false)
    elseif !y.b
        members = filter(v -> !(v in x), y.members)
        return FiniteNominal(OrderedSet(members), false)
    end
    FiniteNominal(union(x.members, y.members), true)
end
Base.union(x::FiniteReal, y::FiniteReal) = FiniteReal(union(x.members, y.members))
Base.union(x::Interval, y::Interval) = Interval(union(x.interval, y.interval))
Base.union(x::FiniteNominal, y::FiniteReal) = Concat(x, y, EMPTY_SET)
Base.union(x::FiniteNominal, y::Interval) = Concat(x, EMPTY_SET, y)
Base.union(x::FiniteReal, y::Interval) = error("Real + interval")
Base.union(x::Concat, y::FiniteNominal) = Concat(union(x.nominal, y), x.singleton, x.intervals)
# Base.union(x::Concat{T,EmptySet}, y::FiniteReal) where {T} = error("concat+real")
Base.union(x::Concat, y::FiniteReal) = error("concat+real")
Base.union(x::Concat, y::Interval) = error("concat + interval")
function Base.union(x::Concat, y::Concat)
    println("nominals")
    println(x.nominal)
    println(y.nominal)
    nominal = union(x.nominal, y.nominal)
    println(nominal)
    singleton = union(x.singleton, y.singleton)
    intervals = union(x.intervals, y.intervals)
    Concat(nominal, singleton, intervals)
end

function union(s::SPPLSet, itrs...) # TODO: Slow?
    ans = s
    for x in itrs
        ans = union(ans, x)
    end
    return ans
end

##############
# Containment
##############
# TODO: Optimize. Use x's type.
Base.in(x, ::EmptySet) = false
Base.in(x, s::FiniteNominal) = !(xor(s.b, x in s.members))
Base.in(x, s::FiniteReal) = (x in s.members)
Base.in(x, s::Interval) = x in s.interval
Base.in(x::AbstractString, s::Concat) = x in s.nominal
Base.in(x::Real, s::Concat) = x in s.singleton || x in s.intervals

Base.isempty(S::EmptySet) = true
Base.isempty(S::FiniteSet) = false
Base.isempty(x::Interval) = isempty(x.interval)

##############
# Convenience
##############
..(a, b) = Interval(Intervals.Interval{Closed,Closed}(a, b))
# const ℝ = -Inf .. Inf

opposite(::Type{Closed}) = Open
opposite(::Type{Open}) = Closed
export EMPTY_SET, FiniteNominal, FiniteReal, Interval, Concat
export complement, invert, ..
