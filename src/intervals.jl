import Base.union, Base.intersect

abstract type SPPLSet end
struct EmptySet <: SPPLSet end
is_all(x::EmptySet) = false
const EMPTY_SET = EmptySet()

abstract type FiniteSet <: SPPLSet end
struct FiniteNominal{T} <: FiniteSet
    members::Set{T}
    b::Bool
end

FiniteNominal(x...; b=true) = FiniteNominal(Set(x), b)
Base.:(==)(x::FiniteNominal, y::FiniteNominal) = x.members == y.members && x.b == y.b

struct FiniteReal{T<:Real} <: FiniteSet
    members::Set{T}
    b::Bool
end
FiniteReal(x::Real...; b=true) = FiniteReal(Set(x), b)
Base.:(==)(x::T, y::T) where {T<:FiniteSet} = x.members == y.members && x.b == y.b
# Base.isapprox(x::FiniteReal, y::FiniteReal) = 

#############
# Intervals
#############
abstract type Bound end
abstract type Bounded <: Bound end
struct Open <: Bounded end
struct Closed <: Bounded end
struct Unbounded <: Bound end
Base.max(::Type{<:Bounded}, ::Type{Unbounded}) = Unbounded
Base.max(::Type{Unbounded}, ::Type{<:Bounded}) = Unbounded
Base.max(::Type{Closed}, ::Type{Open}) = Open
Base.max(::Type{Open}, ::Type{Closed}) = Open
Base.max(::Type{Closed}, ::Type{Closed}) = Closed
Base.max(::Type{Open}, ::Type{Open}) = Open
Base.max(::Type{Unbounded}, ::Type{Unbounded}) = Unbounded
opposite(::Type{Closed}) = Open
opposite(::Type{Open}) = Closed

struct Interval{L<:Bound,R<:Bound,T,U} <: SPPLSet
    f::T
    l::U
    function Interval{L,R,T,U}(f::T, l::U) where {L,R,T,U}
        !isfinite(f) && f == l && error("Error: Unbounded intervals must have different endpoints.")
        ((isfinite(f) && L <: Unbounded) || (isfinite(l) && R <: Unbounded)) && error("Error: Finite ends cannot be unbounded.")
        ((!isfinite(f) && L <: Bounded) || (!isfinite(l) && R <: Bounded)) && error("Error: Infinite endpoints must be unbounded")
        if isfinite(f) && (f == l) && ((L != Closed) || (R != Closed))
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
bounds_match(x::Interval{L,R}, y::Interval{A,B}) where {L,R,A,B} = (L == A && R == B)
Base.:(==)(x::Interval, y::Interval) = x.f == y.f && x.l == y.l && bounds_match(x, y)
Base.isapprox(x::Interval, y::Interval) = x.f ≈ y.f && x.l ≈ y.l && bounds_match(x, y)
Base.first(x::Interval) = x.f
Base.last(x::Interval) = x.l
is_all(x::Interval) = !isfinite(first(x)) && !isfinite(last(x))

#############
# Concat
#############
struct Concat{N,F,I} <: SPPLSet
    nominals::N
    singletons::F
    intervals::I
    function Concat(nominals::N, singletons::R, intervals::I) where {N,R,I}
        if nominals === nothing && singletons === nothing && intervals === nothing
            return EMPTY_SET
        end
        new{N,R,I}(nominals, singletons, intervals)
    end
end
function Concat(nominals::FiniteNominal...)
    Concat(nominals, nothing, nothing)
end
Concat(singletons::FiniteReal...) = Concat(nothing, singletons, nothing)
Concat(intervals::Interval...) = Concat(nothing, nothing, intervals)

# TODO: Consider multiple element versions of complement, union, intersection
#############
# Complement
#############
complement(::EmptySet) = Interval(-Inf, Inf)
complement(x::FiniteNominal) = FiniteNominal(copy(x.members), !x.b) # TODO: Slow?
complement(x::Interval{Unbounded,Unbounded}) = EMPTY_SET
function complement(x::Interval{L,R}) where {L,R}
    left = isfinite(first(x)) ? Interval{Unbounded,opposite(L)}(-Inf, first(x)) : EMPTY_SET
    right = isfinite(last(x)) ? Interval{opposite(R),Unbounded}(last(x), Inf) : EMPTY_SET
    union(left, right)
end

###############
# Intersection
###############
Base.intersect(x::SPPLSet, y::SPPLSet) = 1
Base.intersect(::EmptySet, ::SPPLSet) = EMPTY_SET
Base.intersect(::SPPLSet, ::EmptySet) = EMPTY_SET
function Base.intersect(x::T, y::T) where {T<:FiniteSet}
    !xor(x.b, y.b) && return T(intersect(x.members, y.members), x.b)
    x.b && return T(Set(Iterators.filter(v -> v in y, x.members)), true) # TODO: Non-allocating version
    return T(Set(Iterators.filter(v -> v in x, y.members)), true)
end
function Base.intersect(x::T, y::T, z::T...) where {T<:FiniteSet}
    0
end

function Base.intersect(x::Interval{L,R}, y::Interval{T,U}) where {L,R,T,U} # TODO: Slow
    is_all(x) && return y
    is_all(y) && return x
    if last(x) < first(y) || last(y) < first(x)
        return EMPTY_SET
    end
    start = max(first(x), first(y))
    stop = min(last(x), last(y))
    if start == first(x) && start == first(y)
        left = max(L, T) # Refer to precedence above
    elseif start == first(x) && start != first(y)
        left = L
    else
        left = T
    end

    if stop == last(x) && stop == last(y)
        right = max(R, U) # Refer to precedence above
    elseif stop == last(x) && stop != last(y)
        right = R
    else
        right = U
    end
    return Interval{left,right}(start, stop)
end

##########
# Union
##########
Base.union(x::SPPLSet, y::SPPLSet) = 1
Base.union(::EmptySet, y::SPPLSet) = y
Base.union(x::SPPLSet, ::EmptySet) = x
function Base.union(x::Interval{L,R}, y::Interval{T,U}) where {L,R,T,U}
    is_all(x) && return x
    is_all(y) && return y
    if first(x) > first(y)
        return union(y, x)
    end
    if last(x) < first(y) || (R == Open && T == Open)
        return [x, y]
    end
    return Interval{L,U}(first(x), last(y))
end
function Base.union(x::T, y::T) where {T<:FiniteSet}
    !xor(x.b, y.b) && return T(union(x.members, y.members), true)
    if x.b
        return Concat(x, T(Set(Iterators.filter(v -> !(v in x), y.members)), false))
    end
    return Concat(y, T(Set(Iterators.filter(v -> !(v in y), x.members)), false))
end
function Base.union(x::T...) where {T<:FiniteSet} # TODO: Reduce allocations
    yes = union([v.members for v in Iterators.filter(s -> s.b, x)]...)
    no = union([v.members for v in Iterators.filter(s -> !s.b, x)]...)
    # TODO: Consider simplification, or defer
    return Concat(T(yes, true), T(no, false))
end
# TODO: Add macro to define the reverse?
function Base.union(x::Interval{L,R}, y::FiniteReal{T}) where {L,R,T<:Real}
    error("What")
end

##############
# Containment
##############
Base.in(x, ::EmptySet) = false
Base.in(x, s::T) where {T<:FiniteSet} = !(xor(s.b, x in s.members))
function Base.in(x::Real, int::Interval{L,R}) where {L,R}
    x == Inf == last(int) && return true
    x == -Inf == last(int) && return true
    (x > last(int) || (x == last(int) && R == Open)) && return false
    (x < first(int) || (x == first(int) && L == Open)) && return false
    return true
end

##############
# Convenience
##############
..(x::Real, y::Real) = Interval(x, y)
const ℝ = -Inf .. Inf
export FiniteNominal, FiniteReal, Interval, Concat, Open, Closed, Unbounded, complement, ℝ
