sppl_to_spe(program::Program) = sppl_to_spe(program.env)

function sppl_to_spe(env::Environment)
    leaves = RealLeaf[]
    for (var, def) in env.variables
        if !(def isa Tuple)
            println(def)
            leaf = RealLeaf(var, def, IntervalSet([-Inf.. Inf]))
            push!(leaves, leaf)
        end
    end
    ProductSPE(leaves)
end

