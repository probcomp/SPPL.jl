preimage(f, ::EmptySet) = EMPTY_SET
preimage(f, ::FiniteNominal) = EMPTY_SET

function preimage(f, s::SPPLSet...)
    union(preimage.(Ref(f), s)...)
end
# function preimage(f, s::FiniteReal)
#     I = preimage.(Ref(f), s.members)
#     union(I...)
# end

preimage(::typeof(identity), y) = y
preimage(::typeof(identity), y::FiniteNominal) = y

function preimage(::typeof(sqrt), y::Real)
    y < 0 && return EMPTY_SET
    FiniteReal(y^2)
end
preimage(::typeof(sqrt), y::Interval{Unbounded,Unbounded}) = 0 .. Inf

function preimage(::typeof(sqrt), y::Interval{L,R}) where {L,R}
    if last(y) < 0 || (last(y) == 0 && R == Open)
        return EMPTY_SET
    end
    clipped = first(y) < 0
    left = clipped ? 0 : first(y)^2
    right = last(y)^2
    left_bound = clipped ? Closed : L
    right_bound = R
    return Interval{left_bound,right_bound}(left, right)
end

preimage(::typeof(log), y::Real) = FiniteReal(exp(y))
preimage(::typeof(log), y::Interval{Unbounded,T}) where {T<:Bound} = return Interval{Closed,T}(0.0, exp(last(y)))
preimage(::typeof(log), y::Interval{L,R}) where {L,R} = Interval{L,R}(exp(first(y)), exp(last(y)))

function preimage(::typeof(abs), y::Real)
    y < 0 && return EMPTY_SET
    if y == 0
        return FiniteReal(y)
    end
    FiniteReal(y, -y)
end
preimage(::typeof(abs), y::Interval{Unbounded,Unbounded}) = -Inf .. Inf
function preimage(::typeof(abs), y::Interval{L,R}) where {L,R}
    if last(y) < 0 || (last(y) == 0 && R == Open)
        return EMPTY_SET
    end
    clipped = first(y) < 0
    left = clipped ? 0 : first(y)
    left_bound = clipped ? Closed : L
    union(Interval{R,left_bound}(-last(y), -left), Interval{left_bound,R}(left, last(y)))
end

export preimage, EMPTY_SET
