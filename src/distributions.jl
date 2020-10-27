# Distributions.
Atomic(loc) = dists.atomic(loc=loc)
Choice(d) = dists.NominalDistribution(Dict(d))
Uniform(loc, scale) = dists.uniform(loc=loc, scale=scale)
Bernoulli(p) = dists.bernoulli(p=p)
