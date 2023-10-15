using SPPL

DEBUG = Dict(
    SPPL.DEBUG_SAMPLE=>true,
    SPPL.DEBUG_CONSTANT=>false,
)

val  = @sppl DEBUG  begin
    X ~ Normal(0,2)
    if X < 1
        Z ~ -6*X
    else
        Z ~ sqrt(X)+exp(X)+3*x
    end
end
