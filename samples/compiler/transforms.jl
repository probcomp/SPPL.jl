using SPPL

DEBUG = Dict(
    SPPL.DEBUG_SAMPLE=>false,
    SPPL.DEBUG_SUBSTITUTE=>false,
    SPPL.DEBUG_TRANSFORM=>false,
)

val = @sppl DEBUG begin
    X ~ Normal(0,2)
end

val  = @sppl DEBUG  begin
    a = 1
    b = 2
    c = 3
    d = [[1,2], [3,4]]
    X ~ Normal(0,2)
    Y ~ exp(X)
    A ~ log(exp(X+c))+a
    B ~ X+1
    C ~ a+b*X
    D ~ X^2
    E ~ D * a
end

val  = @sppl DEBUG  begin
    a = 0.5
    X ~ Normal(0,2)
    Y ~ log(exp(X))
    Z ~ Bernoulli(a)
    # A ~ a+b*X
end

spe = SPPL.sppl_to_spe(val)
SPPL.sample(spe)

# val  = @sppl DEBUG  begin
#     a = 3
#     Y ~ 2*a
# end
