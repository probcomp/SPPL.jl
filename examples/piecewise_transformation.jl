module PiecewiseTransformation

include("../src/SPPL.jl")
using .SPPL

n = @sppl begin
    X ~ SPPL.Normal(0, 2)
    X < 1 ? Z -> -X^3 + X^2 + 6*X : Z -> -5 * Sqrt(X) + 11
end

model = n.model
modelc = model.condition((0 < n.Z) < 2)

end # module
