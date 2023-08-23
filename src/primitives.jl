using Distributions
using Symbolics

abstract type SPPLDistribution end

struct DisjointNormal{T} <: SPPLDistribution
    d::Normal{T}
    intervals::Vector{NTuple{2,T}}
    probs::Vector{T}
end

struct DisjointUniform{T} <: SPPLDistribution
    d::Uniform{T}
    intervals::Vector{NTuple{2,T}}
    probs::Vector{T}
end

function DisjointDistribution(d, intervals)
    _dif(i) = cdf(d, i[2]) - cdf(d, i[1])
    probs = _dif.(intervals)
    probs ./= sum(probs)
end

function DisjointNormal(d::Normal{T}, intervals) where {T}
    probs = DisjointDistribution(d, intervals)
    DisjointNormal(d, intervals, probs)
end

function DisjointUniform(d::Uniform{T}, intervals) where {T}
    probs = DisjointDistribution(d, intervals)
    DisjointUniform(d, intervals, probs)
end

function Base.rand(distribution::SPPLDistribution)
    i = 1
    p = distribution.probs
    n = length(p)
    i = 1
    c = p[1]
    u = rand()
    while c < u && i < n
        c += p[i+=1]
    end
    int = distribution.intervals[i]
    d = distribution.d
    x = (u - (i == 1 ? 0.0 : p[i-1])) / p[i] * (cdf(d, int[2]) - cdf(d, int[1])) + cdf(d, int[1])
    quantile(d, x)
end

export DisjointNormal, DisjointUniform
