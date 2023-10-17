sppl_to_spe(program::Program) = sppl_to_spe(program.env)

function sppl_to_spe(env::Environment)
    # leaves = RealLeaf[]
    roots = Symbol[]
    for (var, def) in env.variables
        if !isa(def[2], Tuple)
            push!(roots, var)
        end
        # if !(def isa Tuple)
        #     println(def)
        #     push!(leaves, leaf)
        # end
    end
    dependencies = Dict{Symbol, Vector{Symbol}}()
    # for root in roots
    #     chain = Symbol[]


    #     dependency_chain[root] = chain
    # end
    # display(dependency_chain)

    leaves = map(roots) do var
        RealLeaf(var, getvariable(env, var)[2], IntervalSet([-Inf.. Inf]))
    end

    ProductSPE(leaves)
end

