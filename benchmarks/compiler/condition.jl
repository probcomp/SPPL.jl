using SPPL

DEBUG = Dict(
    SPPL.DEBUG_SAMPLE=>false,
    SPPL.DEBUG_SUBSTITUTE=>false,
    SPPL.DEBUG_CONDITION => true,
)

val = @sppl DEBUG begin
    a = 1
    X ~ Normal(0, 2)
    Condition((X < 1) && (Y > 3))
end

SPPL.@condition (X < 3) && (Y >= 4)