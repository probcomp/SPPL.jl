module DiscreteHMM

using SPPL

@sppl (debug) function sppl_model(n, categories, 
        transition_matrix, obs_matrix)
    latent = array(n)
    X = array(n)

    # Sample initial point.
    latent[0] ~ Choice(zip(categories, [.3, .3, .4]))
    Switch(latent[0], categories) do z
        index = parse(Int, z)
        X[0] ~  Choice(zip(categories, obs_matrix[index]))
    end

    # Sample remaining points.
    for i in 1 : n
        Switch(latent[i-1], categories) do z
            index = parse(Int, z)
            SPPL.Sequence(
                latent[i] ~ Choice(zip(categories, transition_matrix[index])),
                Switch(latent[i], categories) do z
                    index = parse(Int, z)
                    X[i] ~ Choice(zip(categories, obs_matrix[index]))
                end)
        end
    end
end

transition_matrix = [
                     [.1, .4, .5],
                     [.2, .1, .7],
                     [.6, .1, .3]
                    ]

m = sppl_model(5, ["1", "2", "3"],
               transition_matrix, transition_matrix)

end # module
