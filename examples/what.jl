# module MyModule
#     using MacroTools
#     macro flip(expr)
#         expr = MacroTools.shortdef(expr)
#         signature = expr.args[1]
#         println(signature.head)
#         println(signature.args)
#         if length(signature.args) != 3
#             error("Error: Can only @flip functions with two arguments.")
#         end
#         println("signature args", signature.args)
#         flipped = esc(Expr(:call, signature.args[1], signature.args[3], signature.args[2]))
#         quote
#             $(esc(expr))
#             $flipped = $(esc(signature.args[1]))($(esc(signature.args[2])), $(esc(signature.args[3])))
#         end
#         # flipped = Expr(:(=), flipped)
#     end
#     foo(x) = 3
#     export @flip, foo
# end
# using .MyModule

# x = 3
# # @macroexpand @flip g(x,y::Bool) = x+y
# @flip h(x,y::Bool) = begin x end
abstract type Animal{T} end

struct Cat{T} <: Animal{T}
    name::String
end

# Define a function that checks if two arguments have the same abstract type
function check_abstract_type(x, y)
    if Base.promote_type(Base.abstract_type(x), Base.abstract_type(y)) == Base.Nothing
        error("Arguments have different abstract types")
    else
        println("Arguments have the same abstract type")
    end
end
cat_int = Cat{Int}("Whiskers")
cat_float = Cat{Float64}("Oliver")
check_abstract_type(cat_int, cat_float)
@code_warntype check_abstract_type(cat_int, cat_float)
