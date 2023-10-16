using SPPL

DEBUG = Dict(
    SPPL.DEBUG_SAMPLE=>false,
    SPPL.DEBUG_SUBSTITUTE=>false,
    SPPL.DEBUG_TRANSFORM=>false,
)

val  = @sppl DEBUG  begin
    a = 1
    b = 2
    X ~ Normal(0,2)
    Y ~ log(exp(X))
    Z ~ X+1
    A ~ a+b*X
end

val  = @sppl DEBUG  begin
    a = 3
    Y ~ 2*a
end
