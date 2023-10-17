using SPPL
using BenchmarkTools

a = preimage(sqrt, IntervalSet(-3..(-2),@int("(-1,0)")))
a = preimage(sqrt, IntervalSet(-3..(-2),1..5))
a = preimage(sqrt, IntervalSet(1..2, @int("(3,4)")))
a = preimage(sqrt, IntervalSet(-3..(-2), @int("(-1,0)")))
a = preimage(sqrt, IntervalSet(-3..(-2),-1..1, 2..3))