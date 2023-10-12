import Base.union, Base.intersect
using Logging

abstract type SPPLSet end
struct EmptySet <: SPPLSet end
const EMPTY_SET = EmptySet()

abstract type FiniteSet{T} <: SPPLSet end

struct FiniteNominal <: FiniteSet{String}
    members::Set{String}
    b::Bool
    function FiniteNominal(members::AbstractSet{String}, b::Bool, fast=false)
        if !fast
            if length(members) == 0 && b
                return EMPTY_SET
            end
            new(members, b)
        else
            new(members, b)
        end
    end
end
function FiniteNominal(x...; b=true)
    if length(x) == 0
        return FiniteNominal(Set{String}(), b)
    end
    FiniteNominal(Set(x), b)
end
const NOM = FiniteNominal(Set{String}(), false)

struct FiniteReal{T<:Real} <: FiniteSet{T}
    members::Vector{T}
end
function FiniteReal(x::Real...)
    vec = [x...]
    sort!(vec)
    FiniteReal(vec)
end

#############
# Intervals
#############
abstract type Range <: SPPLSet end
struct Interval{T} <: Range # Wrapper around Intervals.jl
    a::T
    b::T
    left::Bool
    right::Bool
    function Interval(a::T, b::U, left::Bool, right::Bool, fast=false) where {T,U}
        if fast
            V = promote_type(T, U)
            return new{V}(a, b, left, right)
        else
            if a == b && (!left || !right)
                return EMPTY_SET
            end
            V = promote_type(T, U)
            b < a && return new{V}(b, a, right, left)
            return new{V}(a, b, left, right)
        end
    end
    function Interval{T}(a::T, b::T, left::Bool, right::Bool) where {T}
        if a == b && (!left || !right)
            return EMPTY_SET
        end
        b < a && return new{T}(b, a, right, left)
        return new{T}(a, b, left, right)
    end
end
Base.first(x::Interval) = x.a
Base.last(x::Interval) = x.b

struct IntervalSet{T} <: Range
    intervals::Vector{T}
    holes::UInt16
end

IntervalSet(x::Interval) = x
# Convenience. Slow.
function IntervalSet(x::Interval, itr...)
    intervals = collect(itr)
    pushfirst!(intervals, x)
    # intervals = (x, itr...)
    IntervalSet(intervals)
end

# Assumes intervals are disjoint
function IntervalSet(intervals::Vector{<:Interval})
    holes = UInt16(0)
    for i = 1:length(intervals)-1
        (last(intervals[i]) == first(intervals[i+1]) && !intervals[i].right && !intervals[i+1].left) && (holes += UInt16(1))
    end
    if first(intervals[1]) == -Inf && !intervals[1].left
        holes += UInt16(1)
    end
    if last(intervals[end]) == Inf && !intervals[end].right
        holes += UInt16(1)
    end
    IntervalSet(intervals, holes)
end


# IntervalSet(a::Real, b::Real, left::Bool=true, right::Bool=true) = Interval(a, b, left, right)

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
Base.:(==)(x::IntervalSet, y::IntervalSet) = x.intervals == y.intervals && x.holes == y.holes
Base.:(==)(x::Concat, y::Concat) = (x.nominal == y.nominal) && (x.singleton == y.singleton) && (x.intervals == y.intervals)

##########
# Invert
##########
invert(x::FiniteNominal) = FiniteNominal(x.members, !x.b) # Ever need to copy x.members?
function invert(x::FiniteReal)
    members = x.members
    new_length = length(members) + 1
    if first(members) == -Inf
        new_length -= 1
    end
    if last(members) == Inf
        new_length -= 1
    end
    intervals = Vector{Interval{Float64}}(undef, new_length)
    j = true
    if first(members) != -Inf
        intervals[1] = Interval(-Inf, first(members), true, false)
    else
        j = false
    end
    for i = 1:length(members)-1
        intervals[i+j] = Interval(members[i], members[i+1], false, false)
    end
    if last(members) != Inf
        intervals[end] = Interval(last(members), Inf, false, true)
    end
    if length(intervals) == 1
        return intervals[1]
    end
    return IntervalSet(intervals)
end

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
    intervals = x.intervals
    new_length = length(intervals) + 1 - x.holes
    if first(intervals[1]) == -Inf && intervals[1].left
        new_length -= 1
    end
    if last(intervals[end]) == Inf && intervals[end].right
        new_length -= 1
    end
    new_intervals = Vector{Interval{Float64}}(undef, new_length)
    singletons = Vector{Float64}(undef, x.holes)
    i = 1
    j = 1
    if first(intervals[1]) == -Inf && !intervals[1].left
        singletons[j] = first(intervals[1])
        j += 1
    else
        int = Interval(-Inf, first(intervals[1]), true, !intervals[1].left)
        if int != EMPTY_SET
            new_intervals[i] = int
            i += 1
        end
    end

    for n = 1:length(intervals)-1
        if last(intervals[n]) == first(intervals[n+1]) && !intervals[n].right && !intervals[n+1].left
            singletons[j] = last(intervals[n])
            j += 1
        else
            new_intervals[i] = Interval(last(intervals[n]), first(intervals[n+1]), !intervals[n].right, !intervals[n+1].left)
            i += 1
        end
    end
    if last(intervals[end]) == Inf && !intervals[end].right
        singletons[j] = last(intervals[end])
        j += 1
    else
        int = Interval(last(intervals[end]), Inf, !intervals[end].right, true)
        if int != EMPTY_SET
            new_intervals[i] = int
            i += 1
        end
    end
    singletons = (length(singletons) == 0 ? EMPTY_SET : FiniteReal(singletons))
    if length(new_intervals) == 0
        set = EMPTY_SET
    elseif length(new_intervals) == 1
        set = new_intervals[1]
    else
        set = IntervalSet(new_intervals, UInt16(0))
    end
    return Concat(EMPTY_SET, singletons, set)
end

# Assumes disjoint and non-touching x and y
function invert(x::FiniteReal, y::Interval)
    A = invert(x)
    B = invert(y)
    intersect(A, B)
end

function invert(x::FiniteReal, y::IntervalSet)
    A = invert(x)
    B = invert(y)
    intersect(A, B)
end

Base.convert(::Type{Interval{Float64}}, x::Interval{Int64}) = Interval(convert(Float64, x.a), convert(Float64, x.b), x.left, x.right)

#############
# Complement
#############

complement(::EmptySet) = Concat(NOM, EMPTY_SET, -Inf .. Inf)
complement(x::FiniteNominal) = Concat(invert(x), EMPTY_SET, -Inf .. Inf)
complement(x::FiniteReal) = Concat(NOM, EMPTY_SET, invert(x))
complement(x::Interval) = Concat(NOM, EMPTY_SET, invert(x))
function complement(x::IntervalSet)
    union(NOM, invert(x))
end
function complement(x::Concat{T,EmptySet,<:Interval}) where {T}
    nominal = invert(x.nominal)
    A = invert(x.intervals)
    union(nominal, A)
end

function complement(x::Concat{T,EmptySet,<:IntervalSet}) where {T}
    nominal = invert(x.nominal)
    A = invert(x.intervals)
    union(nominal, A)
end

function complement(x::Concat{T,U,EmptySet}) where {T,U}
    nominal = invert(x.nominal)
    intervals = invert(x.singleton)
    Concat(nominal, EMPTY_SET, intervals)
end

function complement(x::Concat{EmptySet,T,U}) where {T,U}
    A = invert(x.singleton)
    B = invert(x.intervals)
    intersect(A, B)
end
function complement(x::Concat)
    nominals = invert(x.nominal)
    A = invert(x.singleton, x.intervals)
    union(nominals, A)
end

###############
# Intersection
###############
Base.intersect(x::SPPLSet, y::SPPLSet) = intersect(y, x) # Fallback method
Base.intersect(::EmptySet, y::SPPLSet) = EMPTY_SET
function Base.intersect(x::FiniteNominal, y::FiniteNominal)
    x.b && y.b && return FiniteNominal(intersect(x.members, y.members), true)
    !x.b && !y.b && return FiniteNominal(union(x.members, y.members), false)
    x.b && return FiniteNominal(Set(Iterators.filter(v -> v in y, x.members)), true) # TODO: Non-allocating version
    return FiniteNominal(Set(Iterators.filter(v -> v in x, y.members)), true)
end
Base.intersect(::FiniteNominal, ::FiniteReal) = EMPTY_SET
Base.intersect(::FiniteNominal, ::Interval) = EMPTY_SET
Base.intersect(x::FiniteReal, y::FiniteReal) = FiniteReal(intersect(x.members, y.members))
function Base.intersect(x::FiniteReal, y::Range)
    members = filter(v -> v in y, x.members)
    return length(members) == 0 ? EMPTY_SET : FiniteReal(members)
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
    new_intervals = Interval{Float64}[]
    i = 1
    j = 1
    while i <= length(x.intervals) && j <= length(y.intervals)
        if is_disjoint(x.intervals[i], y.intervals[j])
            if last(x.intervals[i]) < last(y.intervals[j])
                i += 1
            elseif last(x.intervals[i]) > last(y.intervals[j])
                j += 1
            else
                i += 1
                j += 1
            end
        else
            int = intersect(x.intervals[i], y.intervals[j])
            push!(new_intervals, int)
            if last(x.intervals[i]) < last(y.intervals[j])
                i += 1
            elseif last(x.intervals[i]) > last(y.intervals[j])
                j += 1
            else
                i += 1
                j += 1
            end
        end
    end
    length(new_intervals) == 0 && return EMPTY_SET
    return IntervalSet(new_intervals)
end
Base.intersect(x::Concat, y::FiniteNominal) = intersect(x.nominal, y)
Base.intersect(x::Concat, y::FiniteReal) = union(intersect(x.singleton, y), intersect(x.intervals, y))
Base.intersect(x::Concat, y::Range) = union(intersect(x.singleton, y), intersect(x.intervals, y))
function Base.intersect(x::Concat{EmptySet}, y::Concat{EmptySet})
    singleton = intersect(x.singleton, y.singleton)
    intervals = intersect(x.intervals, y.intervals)
    return Concat(EMPTY_SET, singleton, intervals)
end
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
disjoint_union(y::Interval, ::EmptySet) = y
disjoint_union(::EmptySet, ::EmptySet) = EMPTY_SET

Base.union(y::SPPLSet, x::SPPLSet) = union(x, y) # Fallback method
Base.union(::EmptySet, y::SPPLSet) = y
function Base.union(x::FiniteNominal, y::FiniteNominal)
    if !x.b
        members = filter(v -> !(v in y), x.members)
        return FiniteNominal(Set(members), false)
    elseif !y.b
        members = filter(v -> !(v in x), y.members)
        return FiniteNominal(Set(members), false)
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
# Arithmetic
##############
Base.:(*)(x::Interval, y::Real) = Interval(first(x) * y, last(x) * y, x.left, x.right, true)
Base.:(*)(x::FiniteReal, y::Real) = FiniteReal(x.members .* y, true)
Base.:(/)(x::Interval, y::Real) = Interval(first(x) / y, last(x) / y, x.left, x.right, true)
Base.:(/)(x::FiniteReal, y::Real) = FiniteReal(x.members ./ y, true)
Base.:(^)(x::Interval, y::Real) = Interval(first(x)^y, last(x)^y, x.left, x.right, true)
Base.exp(x::Interval) = Interval(exp(first(x)), exp(last(x)), x.left, x.right, true)

# Note: Assumes x is non-negative
Base.log(x::Interval) = Interval(log(first(x)), exp(last(x)), x.left, x.right, true)
Base.sqrt(x::Interval) = Interval(sqrt(first(x)), sqrt(last(x)), x.left, x.right, true)
##############
# Containment
##############
# TODO: Optimize. Use x's type.
Base.in(x, ::EmptySet) = false
Base.in(x, s::FiniteNominal) = !(xor(s.b, x in s.members))
Base.in(x, s::FiniteReal) = insorted(x, s.members)
Base.in(x, s::Interval) = false
Base.in(x::Real, s::Interval) = !((x < first(s) || (first(s) == x && !s.left)) || (x > last(s) || (last(s) == x && !s.right)))
Base.in(x, s::IntervalSet) = false
Base.in(x::Real, s::IntervalSet) = any(v -> x in v, s.intervals)
Base.in(x, s::Concat) = x in s.nominal
Base.in(x::Real, s::Concat) = x in s.singleton || x in s.intervals

Base.isempty(x::SPPLSet) = false
Base.isempty(S::EmptySet) = true

########
# Show
########
Base.show(io::IO, ::MIME"text/plain", ::EmptySet) = print(io, "∅")
function Base.show(io::IO, ::MIME"text/plain", x::FiniteReal)
    print(io, "FiniteReal{")
    print(io, x.members)
    print(io, "}")
end
function Base.show(io::IO, ::MIME"text/plain", x::Interval)
    print(io, x.left ? "[" : "(")
    print(io, "$(first(x)), $(last(x))")
    print(io, x.right ? "]" : ")")
end
function Base.show(io::IO, m::MIME"text/plain", x::IntervalSet{T}) where {T}
    print(io, "{ ")
    for i = 1:length(x.intervals)
        show(io, m, x.intervals[i])
        if i < length(x.intervals)
            print(io, ", ")
        end
    end
    print(io, " }")
end
function Base.show(io::IO, m::MIME"text/plain", x::Concat)
    print(io, "Concat(")
    show(io, m, x.nominal)
    print(io, ", ")
    show(io, m, x.singleton)
    print(io, ", ")
    show(io, m, x.intervals)
    print(io, ")")
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
