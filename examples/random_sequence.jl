module RandomSequence

using SPPL

ns = @sppl (debug) begin
    X = array(3)
    W = array(3)
    X[0] ~ SPPL.Normal()
    for i in 1 : 3
        if X[i - 1] > 0
            X[i] ~ SPPL.Normal(0, 1)
            W[i] ~ SPPL.Atomic(0)
        else
            W[i] ~ SPPL.Bernoulli(0.5)
            W[i] == 0 ? X[i] .> SPPL.Fraction(1, 2) * X[i-1]^2 + X[i-1] : X[i] ~ SPPL.Normal(0, 1)
        end
    end
end

random_sequence = ns.model

# Observe X[1] > 0.
random_sequence_given_X1 = condition(model, ns.X[1] > 0)
println(probability(random_sequence, ns.X[1] > 0))
println(probability(random_sequence_given_X1, ns.X[1] > 0))

# Observe x[2] > 0.
random_sequence_given_X2 = random_sequence.condition(ns.X[2] > 0)
println(probability(random_sequence, ns.X[1] > 0))
println(probability(random_sequence_given_X2, ns.X[1] > 0))

# Compute mutual information.
mutual_information(random_sequence, ns.X[0]>0, ns.X[1]>0) |> println
mutual_information(random_sequence, ns.X[0]>0, ns.X[2]>0) |> println

end # module
