##############
# Transforms
##############
# sub_expr + symbols

#~~~ Functions~~~~#
# get_symbols
# domain
# range
# substitute
# evaluate
preimage(f, ::EmptySet) = EMPTY_SET
preimage(f, y::FiniteNominal) = EMPTY_SET
function preimage(f, y::FiniteReal)
    preimages = preimage.(Ref(f), y.members)
    union(preimages...)
end
function preimage(f, y::IntervalSet)
    preimages = preimage.(Ref(f), y.intervals)
    union(preimages...)
end
function preimage(f, y::Concat)
    singletons = preimage(f, y.singleton)
    intervals = preimage(f, y.intervals)
    union(singletons, intervals)
end


#############
# Identity
#############
preimage(::typeof(identity), y::SPPLSet) = y
preimage(::typeof(identity), y::FiniteNominal) = y
preimage(::typeof(identity), y::Concat) = y
preimage(::typeof(identity), y::Real) = FiniteReal(y)

###############
# Composition
###############
function preimage(f::ComposedFunction, y::Real)
    z = preimage(f.outer, y)
    return preimage(f.inner, z)
end
function preimage(f::ComposedFunction, y::SPPLSet)
    z = preimage(f.outer, y)
    return preimage(f.inner, z)
end

# ###############
# # Square Root
# ###############
function preimage(::typeof(sqrt), y::Real)
    y < 0 && return EMPTY_SET
    FiniteReal(y^2)
end
function preimage(::typeof(sqrt), y::Interval)
    if last(y) < 0 || (last(y) == 0 && !y.right)
        return EMPTY_SET
    end
    clipped = first(y) < 0
    a = clipped ? 0 : first(y)
    b = last(y)
    left = clipped ? true : y.left
    right = y.right
    return Interval(a^2, b^2, left, right)
end

##############
# Logarithm
##############
preimage(::typeof(log), y::Real) = FiniteReal(exp(y))
preimage(::typeof(log), y::Interval) = Interval(exp(first(y)), exp(last(y)), y.left, y.right)

##############
# Exponential
##############
function preimage(::typeof(exp), y::Real)
    y < 0 && return EMPTY_SET
    FiniteReal(log(y))
end
function preimage(::typeof(exp), y::Interval)
    if last(y) < 0 || (last(y) == 0 && !y.right)
        return EMPTY_SET
    end
    clipped = first(y) < 0
    a = clipped ? 0 : first(y)
    b = last(y)
    left = clipped ? true : y.left
    right = y.right
    Interval(log(a), log(b), left, right)
end

##################
# Absolute Value
##################
function preimage(::typeof(abs), y::Real)
    y < 0 && return EMPTY_SET
    y == 0 && return FiniteReal(y)
    FiniteReal(y, -y)
end
function preimage(::typeof(abs), y::Interval)
    if last(y) < 0 || (last(y) == 0 && !y.right)
        return EMPTY_SET
    end
    clipped = first(y) < 0
    a = clipped ? 0 : first(y)
    b = last(y)
    left = clipped ? true : y.left
    right = y.right
    A = Interval(-b, -a, right, left)
    B = Interval(a, b, left, right)
    A ∪ B
end

##############
# Reciprocal
##############

preimage(::typeof(/), y::Real) = y == 0 ? EMPTY_SET : 1 / y
function preimage(::typeof(/), y::Interval)
    # if 0 in y
    #     A = Interval{L,Open}(1 / first(y), 0)
    #     B = Interval{Open,R}(0, 1 / last(y))
    #     println(A)
    #     println(B)
    #     return IntervalSet([A, B])
    # else
    #     return IntervalSet(Interval{L,R}(1 / first(y), 1 / last(y)))
    # end
    error("Not yet implemented")
end

###############
# Polynomials
###############

export preimage
