
struct FiniteNominal
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

Base.:(==)(x::FiniteNominal, y::FiniteNominal) = x.members == y.members && x.b == y.b
invert(x::FiniteNominal) = FiniteNominal(x.members, !x.b) # Ever need to copy x.members?

function Base.intersect(x::FiniteNominal, y::FiniteNominal)
    x.b && y.b && return FiniteNominal(intersect(x.members, y.members), true)
    !x.b && !y.b && return FiniteNominal(union(x.members, y.members), false)
    x.b && return FiniteNominal(Set(Iterators.filter(v -> v in y, x.members)), true) # TODO: Non-allocating version
    return FiniteNominal(Set(Iterators.filter(v -> v in x, y.members)), true)
end

Base.in(x, s::FiniteNominal) = !(xor(s.b, x in s.members))
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

export FiniteNominal