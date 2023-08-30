using Random
import Distributions: pdf, logpdf

abstract type SPE end
prob(spe::SPE, event::Event) = exp(logpdf(spe, event))


###########
# METHODS
###########
#hash
#size
#sample_subset
#sample_func
#sample_many
#transform
#logprob
#condition
#constrain
#mutual_information
#prob
#pdf
#and (as an SPE)
#or (as an SPE)
#partition_list_blocks
#get_symbols

##############
# Leaf SPE
##############

abstract type Leaf <: SPE end
abstract type RealLeaf <: Leaf end

struct ContinuousLeaf{D,I} <: RealLeaf
    symbol::Symbol
    dist::D
    support::I
    is_conditioned::Bool
    env::Dict{Symbol,Function} # TODO: Consider C function pointers
    xl::Float64
    xu::Float64
    Fl::Float64
    Fu::Float64
    logFl::Float64
    logFu::Float64
    Z::Float64
end

function ContinuousLeaf(symbol::Symbol, dist::Distribution, support, env=Dict{Symbol,Function}())
    # Fl = cdf(dist, first(support))
    # Fu = cdf(dist, last(support))
    xl = first(support)
    xu = first(support)
    Fl = 0.0
    Fu = 1.0
    logFl = -Inf
    logFu = 0.0
    Z = 1.0
    ContinuousLeaf(symbol, dist, support, false, env, xl, xu, Fl, Fu, logFl, logFu, Z)
end
function ContinuousLeaf(symbol::Symbol, dist::Distribution)
    ContinuousLeaf(symbol, dist, -Inf .. Inf)
end

struct PiecewiseLeaf{D,I} <: RealLeaf # TODO: For future optimizations on ContinuousLeaf
    symbol::Symbol
    dist::D
    support::I
    is_conditioned::Bool
    env::OrderedDict{Symbol,Function}
end

struct DiscreteLeaf{D,I} <: RealLeaf
    symbol::Symbol
    dist::D
    support::I
    mappings::Dict{Symbol,Float64}
    is_conditioned::Bool
    env::Dict{Symbol,Function}
end

struct NominalLeaf{D<:Categorical} <: Leaf
    symbol::Symbol
    dist::D
    outcomes::Vector{String}
    mappings::Dict{String,Float64}
    support::FiniteNominal
    env::Dict{Symbol,Function}
end
function NominalLeaf(symbol, weights::Vector, support::FiniteNominal, env=Dict{Symbol,Function}())
    !support.b && error("Error: FiniteNominal must not be negated.")
    length(weights) != length(support.members) && error("Error: Mismatched input lengths. The weight and support vectors must have the same length.")
    values = collect(support.members)
    mappings = Dict{String,Float64}(i => j for (i, j) in zip(values, weights))
    NominalLeaf(symbol, Categorical(weights), values, mappings, support, env)
end
NominalLeaf(symbol, weights::Vector, support, env=Dict{Symbol,Function}()) = NominalLeaf(symbol, weights, FiniteNominal(support...), env)
function NominalLeaf(symbol, support)
    n = length(support)
    NominalLeaf(symbol, ones(n) / n, support)
end
############
# Sum SPE
###########

abstract type BranchSPE{T} <: SPE end

struct SumSPE{S<:SPE} <: BranchSPE{S}
    symbols::OrderedSet{Symbol}
    weights::Vector{Float64}
    children::Vector{S}
    function SumSPE(weights::Vector{Float64}, children::Vector{S}) where {S}
        length(weights) != length(children) && error("Error: Mismatched input lengths. The weight and children vector must have the same length.")
        children_symbols = get_symbols.(children)
        all(x -> x == children_symbols[1], children_symbols) || error("Error: Sum SPE scope mismatch. The children do not have the same symbols.")
        # TODO: Lift child SumSPEs up
        new{S}(children_symbols[1], weights, children)
    end
end
function SumSPE(children::Vector{S}) where {S<:SPE}
    n = length(children)
    weights = ones(n) / n
    SumSPE(weights, children)
end


###############
# Product SPE
###############
struct ProductSPE{T<:SPE} <: BranchSPE{T}
    symbols::Set{Symbol}
    children::Vector{T}
    function ProductSPE(children::Vector{T}) where {T}
        children_symbols = get_symbols.(children)
        for (i, child1) in enumerate(children_symbols)
            for (j, child2) in enumerate(children_symbols)
                i == j && continue
                child1 == child2 && error("Product SPE scope mismatch. Children must have different variable scopes.")
            end
        end
        symbols = union(children_symbols...)
        new{T}(symbols, children)
    end
end

#===========================================#
#               Operations                  #
#===========================================#

############
# Scoping
############
symbol(leaf::Leaf) = leaf.symbol
get_symbols(leaf::Leaf) = union(OrderedSet([leaf.symbol]), keys(leaf.env))
get_symbols(spe::BranchSPE) = spe.symbols

############
# Iteration
############
Base.length(s::BranchSPE) = length(s.children)
function Base.iterate(iterable::BranchSPE, state=1)
    if state <= length(iterable.children)
        return (iterable.children[state], state + 1)
    else
        return nothing
    end
end

############
# Sampling
############

Base.eltype(::Type{<:NominalLeaf}) = Dict{Symbol,String}
function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{T}) where {T<:NominalLeaf}
    spe = d[]
    i = rand(rng, spe.dist)
    Dict(symbol(spe) => spe.outcomes[i])
end

Base.eltype(::Type{<:ContinuousLeaf}) = Dict{Symbol,Float64}
function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{T}) where {T<:ContinuousLeaf}
    leaf = d[]
    if leaf.is_conditioned
        dist = leaf.dist
        # support = leaf.support
        Fl = leaf.Fl
        Fu = leaf.Fu
        u = rand(rng)
        r = quantile(dist, u * (Fu - Fl) + Fl)
        return Dict(leaf.symbol => leaf.transform(r))
    else
        return Dict(symbol(leaf) => rand(rng, leaf.dist))
    end
end

Base.eltype(::Type{<:SumSPE{T}}) where {T} = Dict
function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{<:SumSPE})
    spe = d[]
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

# TODO: Consider threading?
function Base.eltype(::Type{<:ProductSPE{<:NominalLeaf}})
    Dict{Symbol,String}
end
function Base.eltype(::Type{<:ProductSPE})
    Dict{Symbol,Union{String,Float64}}
end
# function Base.eltype(::Type{<:ProductSPE{}})
function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{<:ProductSPE})
    spe = d[]
    merge(rand.(Ref(rng), spe.children)...)
end

###########
# Scoring
###########
function pdf(::SPE) end
function logpdf(::SPE) end
function logprob(::SPE) end

function Distributions.logpdf(leaf::Leaf, assignments::Dict{Symbol,T}) where {T}
    !haskey(assignments, leaf.symbol) && error("Error: Symbol not defined.")
    if leaf.is_conditioned
        error("Not yet implemented")
    else
        logpdf(leaf.dist, assignments[leaf.symbol])
    end
end

function Distributions.pdf(leaf::Leaf, assignments::Dict{Symbol,T}) where {T}
    !haskey(assignments, leaf.symbol)
    if leaf.is_conditioned
        error("Not yet implemented")
    else
        pdf(leaf.dist, assignments[leaf.symbol])
    end
end
function Distributions.logpdf(spe::SumSPE, assignments::Dict{Symbol,T}) where {T}
end
function Distributions.logpdf(spe::ProductSPE, assignments::Dict{Symbol,T}) where {T}
end

function logprob(leaf::ContinuousLeaf, event::Event)
    # solved_event = solve(event)
    # values = su
end
function logprob(leaf::DiscreteLeaf, event::Event)
end
function logprob(leaf::NominalLeaf, event::Event)
end

##############
# Condition
##############
function condition(spe::SPE, event::Event) end

function condition(spe::ContinuousLeaf, event::Event)
    solved_event = solve(event)
end
function condition(spe::DiscreteLeaf, event::Event)
end
function condition(spe::NominalLeaf, event::Event)
end
function condition()
end

##############
# Constrain
##############
function constraint(spe::SPE, event::Event) end

###############
# Convenience
###############
# function Base.show(io::IO, spe::T) where {T}
#     print(io, "$(T.name)(")
#     print(io, "$(spe.symbol), $(spe.dist), $(spe.support) )
#     print(io, ")")
# end
function Base.show(io::IO, spe::NominalLeaf)
    print(io, "NominalLeaf(")
    print(io, "$(spe.symbol), $(probs(spe.dist)), $(spe.outcomes)")
    print(io, ")")
end
function Base.show(io::IO, spe::SumSPE)
    print(io, "SumSPE(")
    print(io, "$(spe.symbols), $(spe.weights), $(spe.children)")
    print(io, ")")
end
function Base.show(io::IO, spe::ProductSPE)
    print(io, "SumSPE(")
    print(io, "$(spe.symbols), $(spe.children)")
    print(io, ")")
end



export SPE, BranchSPE, SumSPE, ProductSPE, ContinuousLeaf, DiscreteLeaf, NominalLeaf
export Distributions, Normal
export symbol, get_symbols, logpdf, logprob, pdf
