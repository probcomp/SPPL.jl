struct EMPTY_SET end
preimage(f, ::Type{EMPTY_SET}) = EMPTY_SET
function preimage(::typeof(sqrt), x::Real)
    x < 0 && return EMPTY_SET
    x^2
end

preimage(::typeof(sqrt), x::Interval{Nothing,Unbounded,Unbounded}) = 0 .. nothing

function preimage(::typeof(sqrt), x::Interval{T,A,B}) where {T,A,B}
    if last(x) !== nothing && (last(x) < 0 || (last(x) == 0 && B == Open))
        return EMPTY_SET
    end
    clipped = (first(x) === nothing || first(x) < 0)
    left = clipped ? 0 : first(x)^2
    right = (last(x) === nothing) ? nothing : last(x)^2
    left_bound = clipped ? Closed : A
    right_bound = B
    if left === right && (left_bound == Open || right_bound == Open)
        return EMPTY_SET
    end
    return Interval{left_bound,right_bound}(left, right)
end

preimage(::typeof(log), x::Real) = exp(x)
preimage(::typeof(log), x::Interval{Nothing,Unbounded,Unbounded}) = return Interval(nothing, nothing)
function preimage(::typeof(log), x::Interval{T,A,B}) where {T,A,B}
    left = (first(x) === nothing) ? nothing : exp(first(x))
    right = (last(x) === nothing) ? nothing : exp(last(x))
    if left === right && (A == Open || B == Open)
        return EMPTY_SET
    end
    Interval{A,B}(left, right)
end

function preimage(::typeof(abs), x::Real)
    x < 0 && return EMPTY_SET
    error("Unimplemented finite set")
end
preimage(::typeof(abs), x::Interval{Nothing,Unbounded,Unbounded}) = 0 .. nothing
function preimage(::typeof(abs), x::Interval{T,A,B}) where {T,A,B}
    error("Unimplemented")
end


export preimage, EMPTY_SET
