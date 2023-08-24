import Base.union, Base.intersect

abstract type SPPLSet end
struct EmptySet <: SPPLSet end
is_all(x::EmptySet) = false
complement(::EmptySet) = Interval(Inf, Inf)
const EMPTY_SET = EmptySet()

struct FiniteNominal{T} <: SPPLSet
    members::Set{T}
    b::Bool
end

FiniteNominal(x...;b=true) = FiniteNominal(Set(x), b)

struct FiniteReal{T<:Real} <: SPPLSet
    members::Set{T}
    b::Bool
end
FiniteReal(x::Real...;b=true) = FiniteReal(Set(x), b)

#############
# Intervals
#############
abstract type Bound end
abstract type Bounded <: Bound end
struct Open <: Bounded end
struct Closed <: Bounded end
struct Unbounded <: Bound end

struct Interval{L<:Bound,R<:Bound,T,U} <: SPPLSet
    f::T
    l::U
    function Interval{L,R,T,U}(f::T, l::U) where {L,R,T,U}
        !isfinite(f) && f == l && error("Error: Unbounded intervals must have different endpoints.")
        ((isfinite(f) && L <: Unbounded) || (isfinite(l) && R <: Unbounded)) && error("Error: Finite ends cannot be unbounded.")
        ((!isfinite(f) && L <: Bounded) || (!isfinite(l) && R <: Bounded)) && error("Error: Infinite endpoints must be unbounded")
        if isfinite(f) && (f == l) && ((L != Closed)||(R != Closed))
            return EMPTY_SET
        end
        if l < f
            return new{R,L,U,T}(l, f)
        end
        return new{L,R,T,U}(f, l)
    end
end
function Interval(f::T, l::U) where {T,U}
    L = isfinite(f) ? Closed : Unbounded
    R = isfinite(l) ? Closed : Unbounded
    Interval{L,R,T,U}(f, l)
end
Interval{L,R}(f::T, l::U) where {L,R,T,U} = Interval{L,R,T,U}(f, l)
Base.first(x::Interval) = x.f
Base.last(x::Interval) = x.l
is_all(x::Interval) = !isfinite(first(x)) && !isfinite(last(x))


function Base.union(x::Interval{L,R}, y::Interval{T,U}) where {L,R,T,U}
    is_all(x) && return x
    is_all(y) && return y
    if first(x) > first(y)
        return union(y,x)
    end
    if last(x) < first(y) || (R==Open && T==Open)
        return [x,y]
    end
    return Interval{L,U}(first(x), last(y))
end
function Base.intersect(x::Interval{L,R}, y::Interval{T,U}) where {L,R,T,U}
    is_all(x) && return y
    is_all(y) && return x
    if first(x) > first(y)
        return intersect(y,x)
    end
    if last(x) < first(y)
        return EMPTY_SET
    end
    return Interval{R,T}(last(x), first(y))
end
Base.union(x::EmptySet, y::SPPLSet) = y
Base.union(x::SPPLSet, y::EmptySet) = x
Base.intersect(x::EmptySet, y::SPPLSet) = EMPTY_SET
Base.intersect(x::SPPLSet, y::EmptySet) = EMPTY_SET

@inline Base.union(x::FiniteNominal, y::FiniteNominal) = union(x.members, y.members)
@inline Base.intersect(x::FiniteNominal, y::FiniteNominal) = intersect(x.members, y.members)

Base.union(x::SPPLSet, y::SPPLSet) = 1
Base.intersect(x::SPPLSet, y::SPPLSet) = 1
export FiniteNominal, FiniteReal, Interval, Open, Closed, Unbounded
