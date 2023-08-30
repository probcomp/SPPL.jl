import Base.union, Base.intersect
using OrderedCollections
import Intervals: Intervals
using Logging

abstract type SPPLSet end
struct EmptySet <: SPPLSet end
const EMPTY_SET = EmptySet()

abstract type FiniteSet{T} <: SPPLSet end

struct FiniteNominal <: FiniteSet{String}
    members::OrderedSet{String}
    b::Bool
    function FiniteNominal(members::AbstractSet{String}, b::Bool)
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
const NOM = FiniteNominal(Set{String}(), false)

struct FiniteReal{T<:Real} <: FiniteSet{T}
    members::Set{T}
end
FiniteReal(x::Real...) = FiniteReal(Set(x))

#############
# Intervals
#############
abstract type Range <: SPPLSet end
struct Interval{T} <: Range # Wrapper around Intervals.jl
    a::T
    b::T
    left::Bool
    right::Bool
    function Interval(a::T, b::U, left::Bool, right::Bool) where {T,U}
        if a == b && (!left || !right)
            return EMPTY_SET
        end
        a, b = promote(a, b)
        b < a && return new{T}(b, a, right, left)
        return new{typeof(a)}(a, b, left, right)
    end
end
Base.first(x::Interval) = x.a
Base.last(x::Interval) = x.b

struct IntervalSet{T} <: Range
    intervals::Vector{T}
end

IntervalSet(x::Interval) = x
function IntervalSet(x::Interval, itr...)
    intervals = collect(itr)
    pushfirst!(intervals, x)
    IntervalSet(intervals)
end
IntervalSet(a::Real, b::Real, left::Bool=true, right::Bool=true) = IntervalSet(Interval(a, b, left, right))

#############
# Concat
#############
struct Concat{T<:Union{EmptySet,FiniteNominal},U<:Union{EmptySet,FiniteReal},V<:Union{EmptySet,Range}} <: SPPLSet
    nominal::T
    singleton::U
    intervals::V
end
Concat(::EmptySet, ::EmptySet, ::EmptySet) = EMPTY_SET
Concat(y::FiniteNominal, ::EmptySet, ::EmptySet) = y
Concat(::EmptySet, ::EmptySet, y::Range) = y
Concat(::EmptySet, y::FiniteReal, ::EmptySet) = y

#############
# Equality
#############
Base.:(==)(x::SPPLSet, y::SPPLSet) = false
Base.:(==)(::EmptySet, ::EmptySet) = true
Base.:(==)(x::FiniteNominal, y::FiniteNominal) = x.members == y.members && x.b == y.b
Base.:(==)(x::FiniteReal, y::FiniteReal) = x.members == y.members
Base.:(==)(x::Interval, y::Interval) = x.a == y.a && x.b == y.b && (x.left == y.left) && (x.right == y.right)
Base.:(==)(x::IntervalSet, y::IntervalSet) = error("not yet implemented")
Base.:(==)(x::Concat, y::Concat) = (x.nominal == y.nominal) && (x.singleton == y.singleton) && (x.intervals == y.intervals)

##########
# Invert
##########
# Not exactly complement, but convenient?
invert(x::FiniteNominal) = FiniteNominal(copy(x.members), !x.b) # TODO: Slow?
invert(x::FiniteReal) = intersect(invert.(x.members)...)
function invert(x::Real)
    left = Interval(-Inf, x, true, false)
    right = Interval(x, Inf, false, true)
    IntervalSet([left, right])
end
function invert(x::Interval)
    left = Interval(-Inf, first(x), true, !x.left)
    right = Interval(last(x), Inf, !x.right, true)
    disjoint_union(left, right)
end
function invert(x::IntervalSet)
    error("Not yet implemented")
    # intervals = x.intervals
    # new_intervals = Vector{Interval{Float64}}(undef, length(intervals) + 1)
    # new_intervals[1] = Interval(-Inf, first(intervals[1]), true, !intervals[1].left)
    # for i = 1:length(intervals)-1
    #     a = last(intervals[i])
    #     b = first(intervals[i+1])
    #     left = !intervals[i].right
    #     right = !intervals[i+1].left
    #     new_intervals[i+1] = Interval(a, b, left, right)
    # end
    # new_intervals[end] = Interval(last(intervals[end]), Inf, !intervals[end].right, true)
    # new_intervals
end
convert(::Type{Interval{Float64}}, x::Interval) = Interval(convert(Float64, first(x)), convert(Float64, last(x)), x.left, x.right)

#############
# Complement
#############

complement(::EmptySet) = Concat(NOM, EMPTY_SET, -Inf .. Inf)
complement(x::FiniteNominal) = Concat(invert(x), EMPTY_SET, -Inf .. Inf)
complement(x::FiniteReal) = Concat(NOM, EMPTY_SET, invert(x))
complement(x::Interval) = Concat(NOM, EMPTY_SET, invert(x))
complement(x::IntervalSet) = Concat(NOM, invert(x)...)
function complement(x::Concat{T,EmptySet,U}) where {T,U}
    error("Not yet implemented")
    # Concat(invert(x.nominal))
end
function complement(x::Concat{T,U,EmptySet}) where {T,U}
    error("Not yet implemented")
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
function Base.intersect(x::FiniteReal, y::Range)
    members = filter(v -> v in y, x.members)
    return length(members) == 0 ? EMPTY_SET : FiniteReal(Set(members))
end
function Base.intersect(x::Interval, y::Interval)
    is_disjoint(x, y) && return EMPTY_SET
    start = max(first(x), first(y))
    stop = min(last(x), last(y))
    if first(x) == start && first(y) == start
        left = x.left && y.left
    elseif first(x) == start
        left = x.left
    else
        left = y.left
    end

    if last(x) == stop && last(y) == stop
        right = x.right && y.right
    elseif last(x) == stop
        right = x.right
    else
        right = y.right
    end

    Interval(start, stop, left, right)
end
function Base.intersect(x::Interval, y::IntervalSet)
    intervals = copy(y.intervals)
    start = -1
    for (i, int) in enumerate(intervals)
        if !is_disjoint(x, int)
            start = i
            break
        end
    end
    stop = -1
    for i = length(intervals):-1:1
        if !is_disjoint(x, intervals[i])
            stop = i
            break
        end
    end

    start == -1 && return EMPTY_SET

    intervals = intervals[start:stop]
    intervals[1] = intersect(x, intervals[1])
    intervals[end] = intersect(x, intervals[end])

    if length(intervals) == 1
        return intervals[1]
    end
    return IntervalSet(intervals)
end
function Base.intersect(x::IntervalSet, y::IntervalSet)
    intervals = copy(x.intervals)
    ints = intersect.(intervals, Ref(y))
    union(ints...)
end
Base.intersect(x::Concat, y::FiniteNominal) = intersect(x.nominal, y)
Base.intersect(x::Concat, y::FiniteReal) = union(intersect(x.singleton, y), intersect(x.intervals, y))
Base.intersect(x::Concat, y::Range) = union(intersect(x.singleton, y), intersect(x.intervals, y))
function Base.intersect(x::Concat, y::Concat)
    nominals = intersect(x.nominal, y.nominal)
    singleton = intersect(x.singleton, y.singleton)
    intervals = intersect(x.intervals, y.intervals)
    Concat(nominals, singleton, intervals)
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
@inline function is_disjoint(x::Interval, y::Interval)
    return (last(x) < first(y) || last(y) < first(x)) ||
           (last(x) == first(y) && (!x.right || !y.left)) ||
           (last(y) == first(x) && (!y.right || !x.left))
end
@inline function disjoint_union(x::Interval, y::Interval)
    first(x) < first(y) && return IntervalSet([x, y])
    return IntervalSet([y, x])
end
disjoint_union(::EmptySet, y::Interval) = y
disjoint_union(y::Interval,::EmptySet) = y

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
Base.union(x::FiniteNominal, y::FiniteReal) = Concat(x, y, EMPTY_SET)
Base.union(x::FiniteNominal, y::Range) = Concat(x, EMPTY_SET, y)
Base.union(x::FiniteReal, y::FiniteReal) = FiniteReal(union(x.members, y.members))
Base.union(x::FiniteReal, y::Range) = Concat(EMPTY_SET, x, y)

touch(x::Interval, y::Interval) = !(last(x) < first(y) || last(y) < first(x) ||
                                    (last(x) == first(y) && !x.right && !y.left) || (last(y) == first(x) && !y.right && !x.left))
function Base.union(x::Interval, y::Interval)
    !touch(x, y) && return disjoint_union(x, y)
    if first(x) < first(y)
        start = first(x)
        left = x.left
    elseif first(y) < first(x)
        start = first(y)
        left = y.left
    else
        start = first(x)
        left = x.left || y.left
    end

    if last(x) > last(y)
        stop = last(x)
        right = x.right
    elseif last(y) > last(x)
        stop = last(y)
        right = y.right
    else
        stop = last(x)
        right = x.right || y.right
    end
    Interval(start, stop, left, right)
end

function Base.union(x::Interval, y::IntervalSet)
    intervals = copy(y.intervals)
    start = -1
    for (i, int) in enumerate(intervals)
        if touch(x, int)
            start = i
            break
        end
    end
    stop = -1
    for i = length(intervals):-1:1
        if touch(x, intervals[i])
            stop = i
            break
        end
    end
    if start == -1
        if last(x) <= first(intervals[1])
            pushfirst!(intervals, x)
        elseif first(x) >= last(intervals[end])
            push!(intervals, x)
        else
            for i = 1:length(intervals)-1
                if last(intervals[i]) <= first(x) <= last(x) <= first(intervals[i+1])
                    insert!(intervals, i + 1, x)
                end
            end
        end
    else
        A = union(intervals[start], x)
        int = union(intervals[stop], A)
        splice!(intervals, start:stop, [int])
    end

    if length(intervals) == 1
        return intervals[1]
    end
    return IntervalSet(intervals)
end

function Base.union(x::IntervalSet, y::IntervalSet) # TODO: Slow
    intervals = IntervalSet(copy(x.intervals))
    for int in y.intervals
        intervals = union(int, intervals)
    end
    return intervals
end

Base.union(x::Concat, y::FiniteNominal) = Concat(union(x.nominal, y), x.singleton, x.intervals)
Base.union(x::Concat, y::FiniteReal) = Concat(x.nominal, union(x.singleton, y), x.intervals)
Base.union(x::Concat, y::Range) = Concat(x.nominal, x.singleton, union(x.intervals, y))
function Base.union(x::Concat, y::Concat)
    nominal = union(x.nominal, y.nominal)
    singleton = union(x.singleton, y.singleton)
    intervals = union(x.intervals, y.intervals)
    Concat(nominal, singleton, intervals)
end

function Base.union(s::SPPLSet, itrs...) # TODO: Slow?
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
Base.in(x, s::Interval) = false
Base.in(x::Real, s::Interval) = !((x < first(s) || (first(s) == x && !s.left)) || (x > last(s) || (last(s) == x && !s.right)))
Base.in(x, s::IntervalSet) = false
Base.in(x::Real, s::IntervalSet) = any(v -> x in v, s.intervals)
Base.in(x, s::Concat) = x in s.nominal
Base.in(x::Real, s::Concat) = x in s.singleton || x in s.intervals

Base.isempty(S::EmptySet) = true
Base.isempty(S::FiniteSet) = false
Base.isempty(x::Interval) = false
Base.isempty(x::IntervalSet) = false
Base.isempty(x::Concat) = false

########
# Show
########
Base.show(io::IO, ::MIME"text/plain",::EmptySet) = print(io, "∅")
Base.show(io::IO, ::MIME"text/plain", x::FiniteReal) = print(io, x.members)
Base.show(io::IO,::MIME"text/plain", x::Concat) = print(io, "Concat($(x.nominal), $(x.singleton), $(x.intervals))")
function Base.show(io::IO,::MIME"text/plain", x::Interval)
    print(io, x.left ? "[" : "(")
    print(io, "$(first(x)), $(last(x))")
    print(io, x.right ? "]" : ")")
end
function Base.show(io::IO, m::MIME"text/plain", x::IntervalSet{T}) where {T}
    print(io, "{ ")
    for i=1:length(x.intervals)
        show(io, m, x.intervals[i])
        if i < length(x.intervals)
            print(io, ", ")
        end
    end
    print(io, " }")
end
##############
# Convenience
##############
..(a, b) = Interval(a, b, true, true)

function string_to_num(str::AbstractString)
    parsed_int = tryparse(Int, str)
    parsed_int !== nothing && return parsed_int

    # Try parsing the string as a float
    parsed_float = tryparse(Float64, str)
    parsed_float !== nothing && return parsed_float

    error("Cannot parse $(str)")
end

macro int(ex)
    number = r""
    pattern = r"([\[\(])(.*),(.*)([\)\]])"
    m = match(pattern, ex)
    left = true
    if m[1] == "["
        left = true
    elseif m[1] == "("
        left = false
    else
        error("Must be [ or (")
    end

    if m[4] == "]"
        right = true
    elseif m[4] == ")"
        right = false
    else
        error("Must be ] or )")
    end
    a = string_to_num(m[2])
    b = string_to_num(m[3])
    if b < a
        error("Macro: b < a. Must flip endpoints.")
    end
    a, b = promote(a, b)
    Interval(a, b, left, right)
end
# const ℝ = -Inf .. Inf

export EMPTY_SET, FiniteNominal, FiniteReal, Interval, IntervalSet, Concat
export complement, invert, .., @int, is_disjoint
