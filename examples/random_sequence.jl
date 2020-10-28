module RandomSequence

# Doesn't quite work yet.

include("../src/SPPL.jl")
using .SPPL

#n = @sppl_str (debug) """
#X = array(3)
#W = array(3)
#
#X[0] ~= norm()
#for i in range(1, 3):
#    if X[i-1] > 0:
#        X[i] ~= norm(loc=0, scale=1)
#        W[i] ~= atomic(loc=0)
#    else:
#        W[i] ~= bernoulli(p=0.5)
#        if W[i] == 0:
#            X[i] ~= Fraction(1,2)*X[i-1]**2 + X[i-1]
#        else:
#            X[i] ~= norm(loc=0, scale=1)
#"""

n = @sppl (debug) begin
    X = array(3)
    W = array(3)
    X[1] ~ SPPL.Normal()
    for i in 2 : 3
        if X[i - 1] > 0
            X[i] ~ SPPL.Normal(0, 1)
            W[i] ~ SPPL.Atomic(0)
        else
            W[i] ~ SPPL.Bernoulli(0.5)
            W[i] == 0 ? X[i] ~ SPPL.Fraction(1, 2) * X[i-1]^2 + X[i-1] : X[i] ~ SPPL.Normal(0, 1)
        end
    end
end

end # module
