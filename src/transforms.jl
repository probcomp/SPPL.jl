preimage(f, ::EmptySet) = EMPTY_SET

preimage(::typeof(identity), y) = y

# function preimage(f, y::Vector)
#     preimages = preimage.(Ref(f), y)
#     union(preimages...)
# end

function preimage(::typeof(sqrt), y::Real)
    y < 0 && return EMPTY_SET
    FiniteReal(y^2)
end

preimage(::typeof(sqrt), y::Interval{Unbounded,Unbounded}) = 0..Inf

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
preimage(::typeof(log), y::Interval{Unbounded,Unbounded}) = return Interval(0, Inf)
function preimage(::typeof(log), y::Interval{L,R}) where {L,R}
    left = (first(y) === nothing) ? nothing : exp(first(y))
    right = (last(y) === nothing) ? nothing : exp(last(y))
    Interval{L,R}(left, right)
end

function preimage(::typeof(abs), y::Real)
    y < 0 && return EMPTY_SET
    if y == 0
        return FiniteReal(y)
    end
    FiniteReal(y,-y)
end
preimage(::typeof(abs), y::Interval{Unbounded,Unbounded}) = -Inf..Inf
function preimage(::typeof(abs), y::Interval{L,R}) where {L,R}
    if last(y) < 0 || (last(y) ==0 && R == Open)
        return EMPTY_SET
    end
    clipped = first(y) < 0
    left = clipped ? 0 : first(y)
    left_bound = clipped ? Closed : L
    union(Interval{R,left_bound}(-last(y), -left), Interval{left_bound,R}(left, last(y)))
end


export preimage, EMPTY_SET
