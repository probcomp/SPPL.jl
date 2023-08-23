using Intervals
using Distributions

abstract type SPE end

##############
# Leaf SPE
##############

abstract type LeafSPE <: SPE end

abstract type RealLeaf <: LeafSPE end

struct ContinuousLeaf <: RealLeaf
    symbol::Symbol
    dist::Distribution
    support::Interval
    transform
end


struct DiscreteLeaf <: RealLeaf
    symbol::Symbol
    dist
    support::Interval
    transform
end

struct NominalLeaf <: LeafSPE
    symbol::Symbol
    dist
    support
    probs
    transform
    function NominalLeaf(symbol, dist::Dict)
        outcomes = keys(dist)
        probs = values(dist)
        new(symbol, dist, probs, outcomes)
    end
end

Base.in(x, leaf::LeafSPE) = x in leaf.support

# logpdf(leaf::NominalLeaf, x) = x in outcomes ? dist[x] : 0.0

############
# Sum SPE
###########
# struct SumSPE{T,U<:AbstractVector} <: SPE
#     branch::Distribution
#     leaves::Vector{Distribution}
#     nodes::Vector{SPE}
# end


###############
# Product SPE
###############
# struct ProductSPE{U<:AbstractVector} <: SPE
#     children::Vector{SPE}
# end





# function Base.rand(rng::AbstractRNG, s::SumSPE)
#     i, val = sample(s.branch)
#     leaf_vals = sample.(s.leaves)
#     node_vals = sample.(s.nodes)
#     return stack([val], leaf_vals, node_vals)
# end

# function Base.rand(s::ProductSPE)
#     return sample.(s.nodes)
# end

export Distributions, Intervals, .., Interval, Closed, Open
