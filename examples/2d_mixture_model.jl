module MixtureModel_2D

using SPPL

n = @sppl begin
    X ~ SPPL.Normal(0, 2)
    Y ~ 0.6 * SPPL.Normal(8, 1) | 0.4 * SPPL.Gamma(-3, 3)
end

e0 = ((-4 < n.X) < 4) & ((1 < n.Y^2) < 4)
e1 = ((-1 < n.X) < 1) & ((-1.5 < n.Y) < 6)
modelc = condition(model, e0 | e1)
e = dnf_to_disjoint_union(e0 | e1)
println([n.model.prob(x) for x in e.subexprs])

end # module
