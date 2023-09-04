using Random
import Distributions: pdf, logpdf, support
using Dictionaries

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

# TODO: Consider C function pointers?
abstract type ContinuousLeaf <: RealLeaf end

struct IntervalLeaf{D<:Distribution,I<:Interval,E, F} <: ContinuousLeaf
    symbol::Symbol
    dist::D
    support::I
    env::E
    is_conditioned::Bool
    Fl::Float64
    Fu::Float64
    compiled_sampler::F
end

function IntervalLeaf(symbol::Symbol, dist::Distribution, support::Interval, env)
    f = eval(compile_environment(env))
    (support == -Inf .. Inf) && return IntervalLeaf(symbol, dist, -Inf .. Inf, env, false, 0.0, 1.0, f)
    Fl = cdf(dist, first(support))
    Fu = cdf(dist, last(support))
    IntervalLeaf(symbol, dist, support, env, true, Fl, Fu, f)
end

function IntervalLeaf(symbol::Symbol, dist::Distribution, support::Interval)
    env = Dict(symbol => identity)
    IntervalLeaf(symbol, dist, support, env)
end
struct PiecewiseLeaf{D, I,F} <: ContinuousLeaf
    symbol::Symbol
    dist::D
    support::I
    compiled_sampler::F
end

struct DiscreteLeaf{D,I} <: RealLeaf
    symbol::Symbol
    dist::D
    support::I
    mappings::Dict{Symbol,Float64}
    is_conditioned::Bool
    env::Dict{Symbol,Function}
end

struct NominalLeaf{D<:Categorical, I, E, F} <: Leaf
    symbol::Symbol
    dist::D
    outcomes::Vector{String}
    mappings::Dict{String,Float64}
    support::I
    env::E
    compiled_sampler::F
end

# function NominalLeaf(symbol, weights::Vector, support::FiniteNominal, env=Dict{Symbol,Function}())
#     !support.b && error("Error: FiniteNominal must not be negated.")
#     length(weights) != length(support.members) && error("Error: Mismatched input lengths. The weight and support vectors must have the same length.")
#     values = collect(support.members)
#     mappings = Dict{String,Float64}(i => j for (i, j) in zip(values, weights))
#     NominalLeaf(symbol, Categorical(weights), values, mappings, support, env)
# end
# NominalLeaf(symbol, weights::Vector, support, env=Dict{Symbol,Function}()) = NominalLeaf(symbol, weights, FiniteNominal(support...), env)
# function NominalLeaf(symbol, support)
#     n = length(support)
#     NominalLeaf(symbol, ones(n) / n, support)
# end
############
# Sum SPE
###########

abstract type BranchSPE <: SPE end

struct SumSPE{S<:SPE} <: BranchSPE
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
struct ProductSPE{T} <: BranchSPE
    symbols::Set{Symbol}
    children::T
    function ProductSPE(children::T) where {T}
        children_symbols = get_symbols.(children)
        for (i, child1) in enumerate(children_symbols)
            for (j, child2) in enumerate(children_symbols)
                i == j && continue
                !isempty(intersect(child1, child2)) && error("Product SPE scope mismatch. Children must have different variable scopes.")
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
get_symbols(leaf::Leaf) = keys(leaf.env)
get_symbols(spe::BranchSPE) = spe.symbols

############
# Iteration
############
# Base.length(s::BranchSPE) = length(s.children)
# function Base.iterate(iterable::BranchSPE, state=1)
#     if state <= length(iterable.children)
#         return (iterable.children[state], state + 1)
#     else
#         return nothing
#     end
# end

############
# Support
############
function support(s::SPE) end
support(s::Leaf) = s.support
############
# Sampling
############
# Nominal Leaf
function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{T}) where {T<:NominalLeaf}
    spe = d[]
    i = rand(rng, spe.dist)
    (symbol(spe) => spe.outcomes[i])
end

# Interval Leaf
function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{T}) where {T<:IntervalLeaf}
    leaf = d[]
    if leaf.is_conditioned
        dist = leaf.dist
        Fl = leaf.Fl
        Fu = leaf.Fu
        u = rand(rng)
        x = quantile(dist, u * (Fu - Fl) + Fl)
    else
        x = rand(rng, leaf.dist)
    end
    return leaf.compiled_sampler(x)
end

# SumSPE
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

# ProductSPE
function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{<:ProductSPE})
    spe = d[]
    merge(rand.(Ref(rng), spe.children)...)
end

###########
# Support
###########


###########
# Scoring
###########
# function pdf(::SPE) end
# function logpdf(::SPE, assignment::Dict) end
# function logprob(::SPE, event::Event) end

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

# logprob(spe::SPE, event::Event) = logprob(spe, solve(event))
function logprob(leaf::ContinuousLeaf, event::Event)
    intersect(support(leaf), preimage(event, true))
end
function logprob(leaf::DiscreteLeaf, event::Event)
end
function logprob(leaf::NominalLeaf, event::Event)
end

##############
# Condition
##############
# WARNING: Assume solved event!
function condition(spe::SPE, event::Event) end

function condition(spe::ContinuousLeaf, event::Event)
end
function condition(spe::DiscreteLeaf, event::Event)
end
function condition(spe::NominalLeaf, event::Event)
end

##############
# Constrain
##############
function constraint(spe::SPE, event::Event) end

##############
# Compilation
##############

function compile_environment(env)
    func_name = gensym()
    assignments = [:($var = $f(x)) for (var, f) in env]
    named_tuple = Expr(:tuple, assignments...)
    ex = quote
        function $(func_name)(x)
            $(named_tuple)
        end
    end
    return ex
end

###############
# Convenience
###############
env(spe::SPE) = spe.env

function Base.show(io::IO, spe::NominalLeaf)
    print(io, "NominalLeaf(")
    print(io, "$(spe.symbol), $(probs(spe.dist)), ")
    show(io, spe.outcomes)
    print(io, ")")
end

function Base.show(io::IO, spe::SumSPE)
    print(io, "SumSPE(")
    print(io, "$(spe.symbols), $(spe.weights), $(spe.children)")
    print(io, ")")
end

function Base.show(io::IO, spe::ProductSPE)
    print(io, "ProductSPE(")
    print(io, "$(spe.symbols), $(spe.children)")
    print(io, ")")
end



export SPE, BranchSPE, SumSPE, ProductSPE, IntervalLeaf, DiscreteLeaf, NominalLeaf
export Distributions, Normal
export symbol, get_symbols, support, logpdf, logprob, pdf
export env
