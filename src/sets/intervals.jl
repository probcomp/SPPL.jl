import Base.union, Base.intersect
using Logging

####################
# Real-Valued Sets
####################

abstract type RealSet <: SPPLSet end

struct EmptySet{T} <: RealSet end

struct Interval{T} <: RealSet
    a::T
    b::T
    left::Bool
    right::Bool
    function Interval(a::T, b::T, left::Bool, right::Bool) where {T}
        b < a && return new{T}(b, a, right, left)
        return new{T}(a, b, left, right)
    end
end

Interval(a::T, b::U, left, right) where {T,U} = Interval(promote(a,b)..., left, right)

Base.first(x::Interval) = x.a
Base.last(x::Interval) = x.b
Base.isempty(x::Interval) = x.a == x.b && (!x.left || !x.right)
iswhole(x::Interval{T}) where {T} = (x.a == typemin(T) && x.b == typemax(T) && x.left && x.right)

Base.convert(::Type{Interval{T}}, x::Interval) where {T} = Interval(convert(T, x.a), convert(T, x.b), x.left, x.right)
function Base.convert(::Type{Interval{T}}, x::Interval{I}) where {T,I<:Integer}
    a = (x.a == typemin(I) ? typemin(T) : convert(T, x.a))
    b = (x.b == typemax(I) ? typemax(T) : convert(T, x.b))
    Interval(a,b,x.left, x.right)
end

struct IntervalSet{T} <: RealSet
    intervals::Vector{Interval{T}}
end

function lt(x::Interval, y::Interval)
    first(x) < first(y) || (first(x) == first(y) && x.left && !y.left)
end

function coalesce(i::IntervalSet) 
    sort(i.intervals, lt=lt)
    T = eltype(i)
    new_intervals = T[]
end

Base.promote_rule(::Type{Interval{T}}, ::Type{Interval{U}}) where {T,U} = Interval{promote_type(T,U)}
Base.promote_rule(::Type{IntervalSet{T}}, ::Type{IntervalSet{U}}) where {T,U} = IntervalSet{promote_type(T,U)}

Base.convert(::Type{IntervalSet{T}}, x::IntervalSet) where {T} = IntervalSet(convert(Vector{Interval{T}}, x.intervals))

#############
# Operations
#############

# Equality
Base.:(==)(x::Interval, y::Interval) = x.a == y.a && x.b == y.b && (x.left == y.left) && (x.right == y.right)
Base.:(==)(x::IntervalSet, y::IntervalSet) = x.intervals == y.intervals && x.holes == y.holes

# Complement
function complement(x::Interval{T}) where {T}
    isempty(x) && return IntervalSet([typemin(T)..typemax(T)])

    left = Interval(typemin(T), first(x), true, !x.left)
    right = Interval(last(x), typemax(T), !x.right, true)

    if !isempty(left) && !isempty(right)
        interval = [left, right]
    elseif isempty(left) 
        interval = [right]
    else
        interval = [left]
    end 
    return IntervalSet(interval)
end

complement(x::Real) = complement(x..x)

function complement(x::IntervalSet{T}) where {T}
    intervals = x.intervals
    new_length = length(intervals)+1
    if first(intervals[1]) == typemin(T) && intervals[1].left
        new_length -= 1
    end
    if last(intervals[end]) == typemax(T) && intervals[end].right
        new_length -= 1
    end

    new_intervals = Vector{Interval{T}}(undef, new_length)
    i = 1

    if !(first(intervals[1]) == typemin(T) && intervals[1].left)
        new_intervals[i] = Interval(typemin(T), first(intervals[1]), true, !intervals[1].left)
        i += 1
    end
    for n = 1:length(intervals)-1
        new_intervals[i] = Interval(last(intervals[n]), first(intervals[n+1]), !intervals[n].right, !intervals[n+1].left)
        i += 1
    end
    if !(last(intervals[end]) == typemax(T) && intervals[end].right)
        new_intervals[i] = Interval(last(intervals[end]), typemax(T), !intervals[end].right, true)
    end

    IntervalSet(new_intervals)
end

###############
# Intersection
###############
function unsafe_intersect(x::Interval, y::Interval)
    x, y = promote(x, y)
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

function Base.intersect(x::IntervalSet{T}, y::IntervalSet{U}) where {T,U}
    V = promote_type(T,U)
    x_int = x.intervals
    y_int = y.intervals

    if length(x_int) == 0 || length(y_int) == 0
        return IntervalSet(Interval{V}[])
    end

    new_intervals = Interval{V}[]

    i = 1
    j = 1
    while i <= length(x_int) && j <= length(y_int)
        if is_disjoint(x_int[i], y_int[j])
            if last(x_int[i]) < last(y_int[j])
                i += 1
            elseif last(x_int[i]) > last(y_int[j])
                j += 1
            else
                i += 1
                j += 1
            end
        else
            int = unsafe_intersect(x_int[i], y_int[j])
            push!(new_intervals, int)
            if last(x_int[i]) < last(y_int[j])
                i += 1
            elseif last(x_int[i]) > last(y_int[j])
                j += 1
            else
                i += 1
                j += 1
            end
        end
    end
    return IntervalSet(new_intervals)
end
Base.intersect(x::Interval, y::Interval) = intersect(IntervalSet([x]), IntervalSet([y]))
Base.intersect(x::Interval, y::IntervalSet) = intersect(IntervalSet([x]), y)

##########
# Union
##########
@inline function is_disjoint(x::Interval, y::Interval)
    return (last(x) < first(y) || last(y) < first(x)) ||
           (last(x) == first(y) && (!x.right || !y.left)) ||
           (last(y) == first(x) && (!y.right || !x.left))
end

touch(x::Interval, y::Interval) = !(last(x) < first(y) || last(y) < first(x) ||
                                    (last(x) == first(y) && !x.right && !y.left) || (last(y) == first(x) && !y.right && !x.left))

Base.union(x::Interval, y::Interval) = union(IntervalSet([x]), IntervalSet([y]))
Base.union(x::Interval, y::IntervalSet) = union(IntervalSet([x]), y)

function Base.union(x::IntervalSet{T}, y::IntervalSet{U}) where {T,U}
    V = promote_type(T,U)
    x_int = x.intervals
    y_int = y.intervals

    if length(x_int) == 0 
        return IntervalSet(convert(IntervalSet{V}, x_int))
    end
    if length(y_int) == 0 
        return IntervalSet(convert(IntervalSet{V}, y_int))
    end

    new_intervals = Interval{V}[]
    i = 1
    j = 1

    int = nothing
    while i <= length(x_int) && j <= length(y_int)
        if int === nothing
            if first(x_int[i]) < first(y_int[j])
                int = x_int[i]
            else
                int = y_int[j]
            end
        end

        if touch(int, x_int[i])
            int = unsafe_union(int, x_int[i])
            i+=1
        elseif touch(int, y_int[j])
            int = unsafe_union(int, y_int[j])
            j+=1
        else
            push!(new_intervals, int)
            int = nothing
        end
    end

    if i <= length(x_int)
        if int !== nothing 
            while i <= length(x_int) && touch(int, x_int[i]) 
                int = unsafe_union(int, x_int[i])
                i+=1
            end
            push!(new_intervals, int)
        end
        if i<=length(x_int)
            append!(new_intervals, x_int[i:end])
        end
    end

    if j <= length(y_int)
        if int !== nothing 
            while j <= length(y_int) && touch(int, y_int[j])
                int = unsafe_union(int, y_int[j])
                j+=1
            end
            push!(new_intervals, int)
        end
        if j <= length(y_int)
            append!(new_intervals, y_int[j:end])
        end
    end

    return IntervalSet(new_intervals)
end

function unsafe_union(x::Interval, y::Interval)
    x, y = promote(x, y)

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


##############
# Arithmetic
##############

# TODO: Fix bugs with Integer types. Multiplying typemax/in over/underflows. Consider new struct?

Base.:(*)(x::Interval, y::Real) = Interval(first(x) * y, last(x) * y, x.left, x.right)
Base.:(/)(x::Interval, y::Real) = Interval(first(x) / y, last(x) / y, x.left, x.right)
Base.:(^)(x::Interval, y::Real) = Interval(first(x)^y, last(x)^y, x.left, x.right)

function Base.:(*)(x::Interval{T}, y::Real) where {T<:Integer}
    V = promote_type(T, typeof(y))
    a = first(x) == typemin(T) ? typemin(V) : first(x) * y
    b = last(x) == typemax(T) ? typemax(V) : last(x) * y
    Interval(a, b, x.left, x.right)
end
function Base.:(/)(x::Interval{T}, y::Real) where {T<:Integer}
    V = promote_type(T, typeof(y))
    a = first(x) == typemin(T) ? typemin(V) : first(x) / y
    b = last(x) == typemax(T) ? typemax(V) : last(x) / y
    Interval(a, b, x.left, x.right)
end

function Base.:(^)(x::Interval{T}, y::Real) where {T<:Integer}
    V = promote_type(T, typeof(y))
    a = first(x) == typemin(T) ? typemin(V) : first(x) ^ y
    b = last(x) == typemax(T) ? typemax(V) : last(x) ^ y
    Interval(a, b, x.left, x.right)
end

Base.exp(x::Interval) = Interval(exp(first(x)), exp(last(x)), x.left, x.right)
Base.exp(x::Interval{T}) where {T<:Integer} = exp(convert(Interval{Float64}, x))

Base.log(x::Interval) = Interval(log(first(x)), log(last(x)), x.left, x.right)
Base.log(x::Interval{T}) where {T<:Integer} = log(convert(Interval{Float64}, x))

Base.sqrt(x::Interval) = Interval(sqrt(first(x)), sqrt(last(x)), x.left, x.right)
Base.sqrt(x::Interval{T}) where {T<:Integer} = sqrt(convert(Interval{Float64}, x))

Base.:(*)(x::IntervalSet, y::Real) = IntervalSet(x.intervals * y)
Base.:(/)(x::IntervalSet, y::Real) = IntervalSet(x.intervals / y)
Base.:(^)(x::IntervalSet, y::Real) = IntervalSet(x.intervals .^ y)
Base.exp(x::IntervalSet) = IntervalSet(exp.(x.intervals))
Base.log(x::IntervalSet) = IntervalSet(log.(x.intervals))
Base.sqrt(x::IntervalSet) = IntervalSet(sqrt.(x.intervals))

##############
# Containment
##############
Base.in(x, s::Interval) = false
Base.in(x::Real, s::Interval) = !((x < first(s) || (first(s) == x && !s.left)) || (x > last(s) || (last(s) == x && !s.right)))
Base.in(x, s::IntervalSet) = false
Base.in(x::Real, s::IntervalSet) = any(v -> x in v, s.intervals)

########
# Show
########
Base.show(io::IO, ::MIME"text/plain", ::EmptySet) = print(io, "∅")

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

export Interval, IntervalSet, .., @int, is_disjoint, EmptySet