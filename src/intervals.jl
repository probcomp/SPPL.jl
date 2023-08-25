import Base.union, Base.intersect

abstract type SPPLSet end
struct EmptySet <: SPPLSet end
is_all(x::EmptySet) = false
const EMPTY_SET = EmptySet()

abstract type FiniteSet{T} <: SPPLSet end
Base.:(==)(x::T, y::T) where {T<:FiniteSet} = x.members == y.members && x.b == y.b

struct FiniteNominal{T} <: FiniteSet{T}
    members::Set{T}
    b::Bool
    FiniteNominal{T}(members::Set{T}, b) where {T} = (length(members) == 0) ? EMPTY_SET : new{T}(members, b)
    FiniteNominal(members::Set{T}, b) where {T} = (length(members) == 0) ? EMPTY_SET : new{T}(members, b)
end
FiniteNominal(x...; b=true) = FiniteNominal(Set(x), b)

struct FiniteReal{T<:Real} <: FiniteSet{T}
    members::Set{T}
    b::Bool
    FiniteReal{T}(members::Set{T}, b) where {T} = (length(members) == 0) ? EMPTY_SET : new{T}(members, b)
    FiniteReal(members::Set{T}, b) where {T} = (length(members) == 0) ? EMPTY_SET : new{T}(members, b)
end
FiniteReal(x::Real...; b=true) = FiniteReal(Set(x), b)
# Base.isapprox(x::FiniteReal, y::FiniteReal) = 

#############
# Intervals
#############
abstract type Bound end
abstract type Bounded <: Bound end
struct Open <: Bounded end
struct Closed <: Bounded end
struct Unbounded <: Bound end
Base.intersect(::Type{<:Bounded}, ::Type{Unbounded}) = Unbounded
Base.intersect(::Type{Unbounded}, ::Type{<:Bounded}) = Unbounded
Base.intersect(::Type{Closed}, ::Type{Open}) = Open
Base.intersect(::Type{Open}, ::Type{Closed}) = Open
Base.intersect(::Type{Closed}, ::Type{Closed}) = Closed
Base.intersect(::Type{Open}, ::Type{Open}) = Open
Base.intersect(::Type{Unbounded}, ::Type{Unbounded}) = Unbounded
Base.union(::Type{<:Bounded}, ::Type{Unbounded}) = Unbounded
Base.union(::Type{Unbounded}, ::Type{<:Bounded}) = Unbounded
Base.union(::Type{Open}, ::Type{Open}) = Open
Base.union(::Type{Closed}, ::Type{Open}) = Closed
Base.union(::Type{Open}, ::Type{Closed}) = Closed
Base.union(::Type{Closed}, ::Type{Closed}) = Closed
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
    function Concat(x...)
        nominals = filter(v -> isa(v, FiniteNominal), x)
        singletons = filter(v -> isa(v, FiniteReal), x)
        intervals = filter(v -> isa(v, Interval), x)
        nominals = length(nominals) == 0 ? nothing : nominals
        singletons = length(singletons) == 0 ? nothing : singletons
        intervals = length(intervals) == 0 ? nothing : intervals
        new{typeof(nominals),typeof(singletons),typeof(intervals)}(nominals, singletons, intervals)
    end
    Concat(nominals::FiniteNominal...) = new{typeof(nominals),Nothing,Nothing}(nominals, nothing, nothing)
    Concat(singletons::FiniteReal...) = new{Nothing,typeof(singletons),Nothing}(nothing, singletons, nothing)
    Concat(intervals::Interval...) = new{Nothing,Nothing,typeof(intervals)}(nothing, nothing, intervals)
end
# Base.:(==)(x::Concat, y::Concat) = x.nominals == y.nominals &&
#                                    x.singletons == y.singletons && x.intervals == y.intervals

# TODO: Consider multiple element versions of complement, union, intersection
#############
# Complement
#############
complement(::EmptySet) = Interval(-Inf, Inf)
complement(x::T) where {T<:FiniteSet} = T(copy(x.members), !x.b) # TODO: Slow?
complement(x::Interval{Unbounded,Unbounded}) = EMPTY_SET
function complement(x::Interval{L,R}) where {L,R}
    left = isfinite(first(x)) ? Interval{Unbounded,opposite(L)}(-Inf, first(x)) : EMPTY_SET
    right = isfinite(last(x)) ? Interval{opposite(R),Unbounded}(last(x), Inf) : EMPTY_SET
    union(left, right)
end
# complement(x::Concat) = union(complement(x.nominals), complement(x.singletons), complement(x.intervals))

###############
# Intersection
###############
Base.intersect(::EmptySet, ::SPPLSet) = EMPTY_SET
Base.intersect(::SPPLSet, ::EmptySet) = EMPTY_SET
Base.intersect(::EmptySet, ::EmptySet) = EMPTY_SET
function Base.intersect(x::T, y::T) where {T<:FiniteSet}
    !xor(x.b, y.b) && return T(intersect(x.members, y.members), x.b)
    x.b && return T(Set(Iterators.filter(v -> v in y, x.members)), true) # TODO: Non-allocating version
    return T(Set(Iterators.filter(v -> v in x, y.members)), true)
end
function Base.intersect(x::T...) where {T<:FiniteSet}
    yes = intersect([v.members for v in Iterators.filter(s -> s.b, x)]...)
    no = intersect([v.members for v in Iterators.filter(s -> !s.b, x)]...)
    return T(Set(Iterators.filter(v -> !(v in no), yes)), true)
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
        left = intersect(L, T) # Refer to precedence above
    elseif start == first(x) && start != first(y)
        left = L
    else
        left = T
    end

    if stop == last(x) && stop == last(y)
        right = intersect(R, U) # Refer to precedence above
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
Base.union(x::SPPLSet...) = Concat(x...)
Base.union(::EmptySet, y::SPPLSet) = y
Base.union(x::SPPLSet, ::EmptySet) = x
Base.union(::EmptySet, ::EmptySet) = EMPTY_SET
function Base.union(x::Interval{L,R}, y::Interval{T,U}) where {L,R,T,U}
    (is_all(x) || is_all(y)) && return -Inf .. Inf
    if last(x) < first(y) || last(y) < first(x) # Disjoint
        return Concat(x, y)
    elseif last(x) == first(y) && R == T == Open
        return Concat(x, y)
    elseif first(x) == last(y) && L == U == Open
        return Concat(x, y)
    end
    start = min(first(x), first(y))
    stop = max(last(x), last(y))

    if start == first(x) && start == first(y)
        left = L ∪ T # Refer to precedence above
    elseif start == first(x) && start != first(y)
        left = L
    else
        left = T
    end

    if stop == last(x) && stop == last(y)
        right = R ∪ U # Refer to precedence above
    elseif stop == last(x) && stop != last(y)
        right = R
    else
        right = U
    end
    return Interval{left,right}(start, stop)
end
# function Base.union(x::Interval...)
#     reduce(union, x)
# end

function Base.union(x::T, y::T) where {T<:FiniteSet}
    !xor(x.b, y.b) && return T(union(x.members, y.members), x.b)
    if x.b
        return (x, T(Set(Iterators.filter(v -> !(v in x), y.members)), false))
    end
    return (y, T(Set(Iterators.filter(v -> !(v in y), x.members)), false))
end

function Base.union(x::T...) where {T<:FiniteSet} # TODO: Reduce allocations
    if length(x) == 1
        return x[1]
    end
    yes = [v.members for v in filter(s -> s.b, x)]
    no = [v.members for v in filter(s -> !s.b, x)]

    if length(yes) == 0
        A = EMPTY_SET
    else
        A = T(union(yes...), true)
    end

    if length(no) == 0
        B = EMPTY_SET
    else
        B = T(Set(union(setdiff(no, yes)...)), false)
    end
    return union(A, B)
end
# TODO: Add macro to define the reverse?
# function Base.union(x::Interval{L,R}, y::FiniteReal{T}) where {L,R,T<:Real}
# end

##############
# Containment
##############
Base.in(x, S::SPPLSet) = false
Base.in(x, ::EmptySet) = false
Base.in(x, s::T) where {T<:FiniteSet} = !(xor(s.b, x in s.members))
function Base.in(x::Real, int::Interval{L,R}) where {L,R}
    (x > last(int) || (x == last(int) && R == Open)) && return false
    (x < first(int) || (x == first(int) && L == Open)) && return false
    return true
end
function Base.in(x, s::Concat)
    nominal = s.nominals === nothing ? false : any(v -> x in v, s.nominals)
    nominal && return true
    singletons = s.singletons === nothing ? false : any(v -> x in v, s.singletons)
    singletons && return true
    intervals = s.intervals === nothing ? false : any(v -> x in v, s.intervals)
    return intervals
end
##############
# Convenience
##############
..(x::Real, y::Real) = Interval(x, y)
const ℝ = -Inf .. Inf
export FiniteNominal, FiniteReal, Interval, Concat, Open, Closed, Unbounded, complement, ℝ
