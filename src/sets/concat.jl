#############
# Concat
#############
# struct Concat{T<:Union{EmptySet,FiniteNominal},U<:Union{EmptySet,FiniteReal},V<:Union{EmptySet,Range}} <: SPPLSet
#     nominal::T
#     intervals::V
# end
# Concat(::EmptySet, ::EmptySet) = EMPTY_SET
# Concat(y::FiniteNominal, ::EmptySet) = y
# Concat(::EmptySet, y::Range) = y

# Base.:(==)(x::Concat, y::Concat) = (x.nominal == y.nominal) && (x.singleton == y.singleton) && (x.intervals == y.intervals)

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
Base.in(x, s::Concat) = x in s.nominal
Base.in(x::Real, s::Concat) = x in s.singleton || x in s.intervals
Base.union(x::Concat, y::FiniteNominal) = Concat(union(x.nominal, y), x.singleton, x.intervals)
Base.union(x::Concat, y::FiniteReal) = Concat(x.nominal, union(x.singleton, y), x.intervals)
Base.union(x::Concat, y::Range) = Concat(x.nominal, x.singleton, union(x.intervals, y))
function Base.union(x::Concat, y::Concat)
    nominal = union(x.nominal, y.nominal)
    singleton = union(x.singleton, y.singleton)
    intervals = union(x.intervals, y.intervals)
    Concat(nominal, singleton, intervals)
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

# function complement(x::Concat{T,EmptySet,<:Interval}) where {T}
#     nominal = invert(x.nominal)
#     A = invert(x.intervals)
#     union(nominal, A)
# end

# function complement(x::Concat{T,EmptySet,<:IntervalSet}) where {T}
#     nominal = invert(x.nominal)
#     A = invert(x.intervals)
#     union(nominal, A)
# end

# function complement(x::Concat{T,U,EmptySet}) where {T,U}
#     nominal = invert(x.nominal)
#     intervals = invert(x.singleton)
#     Concat(nominal, EMPTY_SET, intervals)
# end

# function complement(x::Concat{EmptySet,T,U}) where {T,U}
#     A = invert(x.singleton)
#     B = invert(x.intervals)
#     intersect(A, B)
# end
# function complement(x::Concat)
#     nominals = invert(x.nominal)
#     A = invert(x.singleton, x.intervals)
#     union(nominals, A)
# end
export Concat