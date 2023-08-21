using Distributions
abstract type SPPLDistribution end

struct DisjointNormal{T} <: SPPLDistribution
    d::Normal{T}
    intervals::Vector{NTuple{2,Float32}}
    probs::Vector{Float32}
    function DisjointNormal(d::Normal{T}, intervals) where {T}
        dif(i) = cdf(d, i[2]) - cdf(d, i[1])
        probs = dif.(intervals)
        probs ./= sum(probs)
        new{T}(d, intervals, probs)
    end
end

function Base.rand(d::SPPL.Uniform)
    i = 1
    p = d.probs
    n = length(p)
    i = 1
    c = p[1]
    u = rand()
    while c < u && i < n
        c += p[i+=1]
    end
    delta = u - (i == 1 ? 0.0 : p[i-1]) + d.intervals[i][1]
end

function Base.rand(distribution::DisjointNormal)
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
export DisjointNormal
