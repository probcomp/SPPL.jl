using SPPL

DEBUG = Dict(
    SPPL.DEBUG_SAMPLE=>false,
    SPPL.DEBUG_SUBSTITUTE=>false,
)

val = @sppl DEBUG begin
    a = 1
    Y ~ Normal(0, 2)

    Switch(Y, 1 : 2) do y
        Z ~ Bernoulli(1 / (1 + y))
        Switch(Z, 0:1) do z
            A ~ Normal(z, a)
        end
    end
end