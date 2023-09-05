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

ContinuousLeaf(symbol, dist, support::Interval, env) = IntervalLeaf(symbol, dist, support, env)
ContinuousLeaf(symbol, dist, support::IntervalSet, env) = PiecewiseLeaf(symbol, dist, support, env)
struct IntervalLeaf{D<:Distribution,I<:Interval,E, F} <: ContinuousLeaf
    symbol::Symbol
    dist::D
    support::I
    env::E
    is_conditioned::Bool
    Fl::Float64
    Fu::Float64
    Z::Float64
    compiled_sampler::F
end

function IntervalLeaf(symbol::Symbol, dist::Distribution, support::Interval, env)
    f = eval(compile_environment(env))
    (support == -Inf .. Inf) && return IntervalLeaf(symbol, dist, -Inf .. Inf, env, false, 0.0, 1.0, 1.0, f)
    Fl = cdf(dist, first(support))
    Fu = cdf(dist, last(support))
    IntervalLeaf(symbol, dist, support, env, true, Fl, Fu, Fu-Fl, f)
end

function IntervalLeaf(symbol::Symbol, dist::Distribution, support::Interval)
    env = Dict(symbol => identity)
    IntervalLeaf(symbol, dist, support, env)
end

struct PiecewiseLeaf{D,I<:IntervalSet,E,T,F} <: ContinuousLeaf
    symbol::Symbol
    dist::D
    support::I
    env::E
    is_conditioned::Bool
    Fl::T
    Fu::T
    weights::T
    Z::Float64
    compiled_sampler::F
end

# Really a Sum SPE, but is specialized to an interval set so this is still a leaf.
function PiecewiseLeaf(symbol::Symbol, dist::Distribution, support::IntervalSet, env)
    f = eval(compile_environment(env))
    (support == -Inf .. Inf) && return PiecewiseLeaf(symbol, dist, -Inf .. Inf, env, false, 0.0, 1.0, 1.0, f)
    Fl = cdf.(Ref(dist), first.(support.intervals))
    Fu = cdf.(Ref(dist), last.(support.intervals))
    weights = Fu .- Fl
    Z = sum(weights)
    weights ./= Z
    Fl = tuple(Fl...)
    Fu = tuple(Fu...)
    weights = tuple(weights...)
    PiecewiseLeaf(symbol, dist, support, env, true, Fl, Fu, weights, Z, f)
end

function PiecewiseLeaf(symbol::Symbol, dist::Distribution, support::IntervalSet)
    env = Dict(symbol => identity)
    PiecewiseLeaf(symbol, dist, support, env)
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
    Z::Float64
    function SumSPE(weights::Vector{Float64}, children::Vector{S}) where {S}
        length(weights) != length(children) && error("Error: Mismatched input lengths. The weight and children vector must have the same length.")
        children_symbols = get_symbols.(children)
        all(x -> x == children_symbols[1], children_symbols) || error("Error: Sum SPE scope mismatch. The children do not have the same symbols.")
        Z = sum(weights .* partition.(children))
        # TODO: Lift child SumSPEs up
        new{S}(children_symbols[1], weights, children, Z)
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
    Z::Float64
    function ProductSPE(children::T) where {T}
        children_symbols = get_symbols.(children)
        for (i, child1) in enumerate(children_symbols)
            for (j, child2) in enumerate(children_symbols)
                i == j && continue
                !isempty(intersect(child1, child2)) && error("Product SPE scope mismatch. Children must have different variable scopes.")
            end
        end
        symbols = union(children_symbols...)
        Z = prod(partition.(children))
        new{T}(symbols, children, Z)
    end
end

#===========================================#
#               Operations                  #
#===========================================#

#########
# Scope
#########
symbol(leaf::Leaf) = leaf.symbol
get_symbols(leaf::Leaf) = keys(leaf.env)
get_symbols(spe::BranchSPE) = spe.symbols

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

function Random.rand(rng::AbstractRNG, d::Random.SamplerTrivial{T}) where {T<:PiecewiseLeaf}
    leaf = d[]
    weights = leaf.weights
    u = rand(rng)
    i = 1
    n = length(weights)
    c = 0.0
    Fl = leaf.Fl
    Fu = leaf.Fu
    while i < n
        if c + weights[i] > u
            break
        end
        c += weights[i]
        i+=1
    end
    delta = (i==1 ? u : (u - c)) / weights[i]
    F = delta * (Fu[i] - Fl[i])  + Fl[i]
    x = quantile(leaf.dist, F)
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
# Scoring
###########
# function pdf(::SPE) end
# function logpdf(::SPE, assignment::Dict) end
# function logprob(::SPE, event::Event) end
# Distributions.logpdf(leaf::Leaf, val) =  logpdf(leaf.dist, val)
function Distributions.logpdf(leaf::Leaf, assignments)
    val = assignments[symbol(leaf)]
    if leaf.is_conditioned
        error("Not yet implemented")
    else
        logpdf(leaf.dist, val)
    end
end

function Distributions.pdf(leaf::Leaf, assignments)
    val = assignments[symbol(leaf)]
    if leaf.is_conditioned
        error("Not yet implemented")
    else
        pdf(leaf.dist, val)
    end
end
function Distributions.logpdf(spe::SumSPE, assignments)
end

function Distributions.logpdf(spe::ProductSPE, assignments)
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
function condition(spe::SPE, event::Event) end

function condition(spe::ContinuousLeaf, event)
    !(event.symbol in get_symbols(spe)) && return spe
    S = preimage(env(spe)[event.symbol], event.predicate)
    new_support = intersect(support(spe), S)
    isempty(new_support) && error("Cannot have empty support")
    ContinuousLeaf(symbol(spe), spe.dist, new_support, env(spe))
end

function condition(spe::SumSPE, event::Event)
    new_children = condition.(spe.children, Ref(event))
    Zs = map(c->c.Z, new_children)
    weights_new = spe.weights .* Zs
    Z = sum(weights_new)
    weights_new ./= Z
    SumSPE(weights_new, new_children)
end
function condition(spe::ProductSPE, event::Event)
    new_children = condition.(spe.children, Ref(event))
    ProductSPE(new_children)
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
partition(spe::SPE) = spe.Z
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



export SPE, BranchSPE, SumSPE, ProductSPE, IntervalLeaf, PiecewiseLeaf, DiscreteLeaf, NominalLeaf
export Distributions, Normal
export symbol, get_symbols, support, logpdf, logprob, pdf, condition
export env, partition
