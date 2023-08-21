module SPPL
import Base: rand

include("intervals.jl")
include("primitives.jl")

abstract type Node end

struct SumNode{T,U<:AbstractVector} <: Node
    branch::Distribution
    leaves::Vector{Distribution}
    nodes::Vector{Node}
end

struct ProductNode{U<:AbstractVector} <: Node
    nodes::Vector{Node}
end

struct Leaf{D<:Distribution} <: Node
    d::D
end

function Base.rand(s::SumNode)
    i, val = sample(s.branch)
    leaf_vals = sample.(s.leaves)
    node_vals = sample.(s.nodes)
    return stack([val], leaf_vals, node_vals)
end

function Base.rand(s::ProductNode) 
    return sample.(s.nodes)
end

Base.rand(s::Leaf) = rand(s.d)

export SumNode, ProductNode, Leaf
end
