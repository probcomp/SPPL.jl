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
# function preimage(f, y::FiniteReal)
#     A = union(preimage.(Ref(f), y.members)...)
#     y.b ? A : complement(A)
# end
# function preimage(f, y::IntervalSet)
#     arr = convert(Array, y)
#     union(preimage.(Ref(f), arr)...)
# end

# #############
# # Identity
# #############
preimage(::typeof(identity), y::Union{Interval,IntervalSet,FiniteReal}) = y
preimage(::typeof(identity), y::FiniteNominal) = y
preimage(::typeof(identity), y::Real) = FiniteReal(y)

# ###############
# # Square Root
# ###############
function preimage(::typeof(sqrt), y::Real)
    y < 0 && return EMPTY_SET
    FiniteReal(y^2)
end
# function preimage(::typeof(sqrt), y::Interval)
#     if last(y) < 0 || (last(y) == 0 && R == Open)
#         return EMPTY_SET
#     end
#     clipped = first(y) < 0
#     left = clipped ? 0 : first(y)^2
#     right = last(y)^2
#     left_bound = clipped ? Closed : L
#     right_bound = R
#     return IntervalSet(Interval{left_bound,right_bound}(left, last(y)^2))
# end

# ##############
# # Logarithm
# ##############
preimage(::typeof(log), y::Real) = FiniteReal(exp(y))
preimage(::typeof(log), y::Interval) = exp(first(y)) .. exp(last(y))

# ##################
# # Absolute Value
# ##################
# function preimage(::typeof(abs), y::Real)
#     y < 0 && return EMPTY_SET
#     if y == 0
#         return FiniteReal(y)
#     end
#     FiniteReal(y, -y)
# end
# function preimage(::typeof(abs), y::Interval{T,L,R}) where {T,L,R}
#     if last(y) < 0 || (last(y) == 0 && R == Open)
#         return EMPTY_SET
#     end
#     clipped = first(y) < 0
#     left = clipped ? 0 : first(y)
#     left_endpoint = clipped ? Closed : L
#     A = IntervalSet(Interval{R,left_endpoint}(-last(y), -left))
#     B = IntervalSet(Interval{left_endpoint,R}(left, last(y)))
#     A ∪ B
# end

# ##############
# # Reciprocal
# ##############

# preimage(::typeof(/), y::Real) = y == 0 ? EMPTY_SET : 1 / y
# function preimage(::typeof(/), y::Interval{T,L,R}) where {T,L,R}
#     if 0 in y
#         A = Interval{L,Open}(1 / first(y), 0)
#         B = Interval{Open,R}(0, 1 / last(y))
#         println(A)
#         println(B)
#         return IntervalSet([A, B])
#     else
#         return IntervalSet(Interval{L,R}(1 / first(y), 1 / last(y)))
#     end
# end

# ###############
# # Polynomials
# ###############

export preimage
