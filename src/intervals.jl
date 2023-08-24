import Base.union, Base.intersect
struct EmptySet end
const EMPTY_SET = EmptySet()

struct FiniteNominal{T<:Set}
    members::T
end

struct FiniteReal{T<:Set}
    members::T
end
struct UnionSet
    nominal::Vector{FiniteNominal}
    finitereal::Vector{FiniteNominal}
    interval::Vector{Intervals}
end

@inline Base.union(x::FiniteNominal, y::FiniteNominal) = union(x.members, y.members)
@inline Base.intersect(x::FiniteNominal, y::FiniteNominal) = intersect(x.members, y.members)
export FiniteNominal
