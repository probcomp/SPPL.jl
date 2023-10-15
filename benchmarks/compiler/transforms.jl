using SPPL

DEBUG = Dict(
    SPPL.DEBUG_SAMPLE=>true,
    SPPL.DEBUG_CONSTANT=>false,
)

val  = @sppl DEBUG  begin
    X ~ Normal(0,2)
    Y ~ 2*X + exp(X)

    a = 3
    Z ~ a * Y
end

