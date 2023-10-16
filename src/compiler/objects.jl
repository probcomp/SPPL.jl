mutable struct Environment 
    constants :: Dict{Symbol, Any}
    variables :: Dict{Symbol, Any}
    arrays :: Dict{Symbol, Any}
    children::Vector{Environment}
    parent::Union{Nothing, Environment}
    # errors:: Vector{String}
end

function Environment()
    return Environment(
        Dict{Symbol, Any}(), 
        Dict{Symbol, Any}(), 
        Dict{Symbol, Any}(),
        Vector{Environment}[],
        nothing
        )
end

# push!(env.errors, error); return
function new_scope(env)
    new = Environment()
    new.parent = env
    push!(env.children, new)
    return new
end

function Base.getindex(env::Environment, ident)
    if haskey(env.constants, ident)
        return env.constants[ident]
    elseif env.parent === nothing
        return nothing
    else
        return getindex(env.parent, ident)
    end
end

function Base.haskey(env::Environment, ident)
    if haskey(env.constants, ident)
        return true
    elseif env.parent === nothing    
        return false
    else
        return haskey(env.parent, ident)
    end
end

function Base.setindex!(env::Environment, ident, value)
    setindex!(env.constants, ident, value) 
end

function getvariable(env::Environment, ident)
    if haskey(env.variables, ident)
        return env.variables[ident]
    elseif env.parent === nothing
        return nothing
    else
        return getindex(env.parent, ident)
    end
end

function hasvariable(env::Environment, ident)
    if haskey(env.variables, ident)
        return true
    elseif env.parent === nothing
        return false
    else
        return hasvariable(env.parent, ident)
    end
end

function setvariable!(env::Environment, ident, value)
    setindex!(env.variables, ident, value)
end

struct Program 
    env::Environment
    errors::Vector{String}
end