
preimage(f, ::EmptySet) = EMPTY_SET

preimage(::typeof(identity), y) = y

function preimage(f, y::Vector)
    preimages = preimage.(Ref(f), y)
    union(preimages...)
end

function preimage(::typeof(sqrt), y::Real)
    y < 0 && return EMPTY_SET
    y^2
end

preimage(::typeof(sqrt), y::Interval{Nothing,Unbounded,Unbounded}) = 0 .. nothing

function preimage(::typeof(sqrt), y::Interval{T,A,B}) where {T,A,B}
    if last(y) !== nothing && (last(y) < 0 || (last(y) == 0 && B == Open))
        return EMPTY_SET
    end
    clipped = (first(y) === nothing || first(y) < 0)
    left = clipped ? 0 : first(y)^2
    right = (last(y) === nothing) ? nothing : last(y)^2
    left_bound = clipped ? Closed : A
    right_bound = B
    if left === right && (left_bound == Open || right_bound == Open)
        return EMPTY_SET
    end
    return Interval{left_bound,right_bound}(left, right)
end

preimage(::typeof(log), y::Real) = exp(y)
preimage(::typeof(log), y::Interval{Nothing,Unbounded,Unbounded}) = return Interval(nothing, nothing)
function preimage(::typeof(log), y::Interval{T,A,B}) where {T,A,B}
    left = (first(y) === nothing) ? nothing : exp(first(y))
    right = (last(y) === nothing) ? nothing : exp(last(y))
    if left === right && (A == Open || B == Open)
        return EMPTY_SET
    end
    Interval{A,B}(left, right)
end

function preimage(::typeof(abs), y::Real)
    y < 0 && return EMPTY_SET
    error("Unimplemented finite set")
end
preimage(::typeof(abs), y::Interval{Nothing,Unbounded,Unbounded}) = 0 .. nothing
function preimage(::typeof(abs), y::Interval{T,A,B}) where {T,A,B}
    error("Unimplemented")
end


export preimage, EMPTY_SET
