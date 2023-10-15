import Base.union, Base.intersect

abstract type SPPLSet end

# struct EmptySet <: SPPLSet end
# EMPTY_SET = EmptySet()
# Base.:(==)(x::SPPLSet, y::SPPLSet) = false
# Base.:(==)(::EmptySet, ::EmptySet) = true
Base.intersect(x::SPPLSet, y::SPPLSet) = intersect(y, x) # Fallback method
# Base.intersect(::EmptySet, y::SPPLSet) = EMPTY_SET
# Base.isempty(x::SPPLSet) = false
# Base.isempty(S::EmptySet) = true

# disjoint_union(::EmptySet, y::Interval) = y
# disjoint_union(y::Interval, ::EmptySet) = y
# disjoint_union(::EmptySet, ::EmptySet) = EMPTY_SET

Base.union(y::SPPLSet, x::SPPLSet) = union(x, y) # Fallback method
# Base.union(::EmptySet, y::SPPLSet) = y

function Base.union(s::SPPLSet, itrs...) # TODO: Slow?
    ans = s
    for x in itrs
        ans = union(ans, x)
    end
    return ans
end

function Base.intersect(s::SPPLSet, itrs...)
    ans = s
    for x in itrs
        ans = intersect(ans, x)
    end
    return ans
end

include("intervals.jl")
# include("nominal.jl")
# include("concat.jl")

# Base.intersect(::FiniteNominal, ::Interval) = EMPTY_SET


#############
# Complement
#############

# complement(::EmptySet) = -Inf .. Inf
# complement(x::FiniteNominal) = Concat(invert(x), EMPTY_SET, -Inf .. Inf)
# complement(x::FiniteReal) = Concat(NOM, EMPTY_SET, invert(x))
# complement(x::Interval) = Concat(NOM, EMPTY_SET, invert(x))
# function complement(x::IntervalSet)
#     union(NOM, invert(x))
# end
export EMPTY_SET
export complement, invert