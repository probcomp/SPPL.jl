using SPPL

DEBUG = Dict(
    SPPL.DEBUG_SAMPLE=>false,
    SPPL.DEBUG_CONSTANT=>true,
)

val = @sppl DEBUG begin
    a = 2
    b = [[5, 7], [5,15]]
    c = 1
    X ~ Normal(0, 2)
    Y ~ Bernoulli(c)

    Switch(Y, 1 : 3) do y
        Z ~ Bernoulli(1 / (1 + y))
        Switch(Z, 0:1) do z
            A ~ Normal(z, a)
        end
    end
end


val = @sppl false begin
    X ~ Normal(0,1)
    if X > 0
        W ~ 2 * X
    elseif X > 3
        W ~ X+1
    elseif X> 5
        W ~ X+1
    else
        W ~ 2*X
    end
end

val = @sppl false begin
    a = 3
    b = [[1, 2], [3,4]]
    c = a*2
    d = b * a
end