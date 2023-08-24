using Intervals
using Distributions

abstract type SPE end

##############
# Leaf SPE
##############

abstract type Leaf <: SPE end

get_symbols(leaf::Leaf) = Set{Symbol}([leaf.symbol])

abstract type RealLeaf <: Leaf end

struct ContinuousLeaf <: RealLeaf
    symbol::Symbol
    dist::Distribution
    support
    transform
end

function Base.rand(rng::AbstractRNG, leaf::ContinuousLeaf)
    dist = leaf.dist
    support = leaf.support
    u = rand(rng)
    Fa = cdf(dist, first(support))
    Fb = cdf(dist, last(support))
    r = quantile(dist, u * (Fb - Fa) + Fa)
    Dict(leaf.symbol => leaf.transform(r))
end

struct DiscreteLeaf <: RealLeaf
    symbol::Symbol
    dist
    support::Interval
    transform
end

function Base.rand(rng::AbstractRNG, leaf::DiscreteLeaf)
    u = rand(rng)
    dist = leaf.dist
end

struct NominalLeaf <: Leaf
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

Base.in(x, leaf::Leaf) = x in leaf.support

############
# Sum SPE
###########
abstract type BranchSPE <: SPE end
get_symbols(spe::BranchSPE) = reduce(union, get_symbols.(spe.children))

struct SumSPE{T<:AbstractFloat,S<:SPE} <: BranchSPE
    weights::Vector{T}
    children::Vector{S}
    function SumSPE(weights::Vector{T}, children::Vector{S}) where {T,S}
        length(weights) != length(children) && error("Error: Mismatched input lengths. The weight and children vector must have the same length.")
        children_symbols = get_symbols.(children)
        all(x -> x == children_symbols[1], children_symbols) || error("Error: Sum SPE scope mismatch. The children do not have the same symbols.")
        # TODO: One optimization is to inspect children if they are sumnodes and lift it's children. 
        new{T,S}(weights, children)
    end
end

function Base.rand(rng::AbstractRNG, spe::SumSPE)
    weights = spe.weights
    children = spe.children
    u = rand(rng)
    i = 1
    n = length(weights)
    c = weights[1]
    while c < u && i < n
        c += weights[i+=1]
    end
    rand(rng, children[i])
end

###############
# Product SPE
###############
struct ProductSPE{T<:SPE} <: BranchSPE
    children::Vector{T}
    function ProductSPE(children::Vector{T}) where {T}
        children_symbols = get_symbols.(children)
        for (i, child1) in enumerate(children_symbols)
            for (j, child2) in enumerate(children_symbols)
                i == j && continue
                child1 == child2 && error("Product SPE scope mismatch. Children must have different variable scopes.")
            end
        end
        new{T}(children)
    end
end

function Base.rand(rng::AbstractRNG, spe::ProductSPE)
    # TODO: Consider threading?
    samples = reduce(merge, rand.(Ref(rng), spe.children))
    samples
end

export SumSPE, ProductSPE, ContinuousLeaf, DiscreteLeaf, NominalLeaf, get_symbols
export Distributions, Intervals, .., Interval, Closed, Open
