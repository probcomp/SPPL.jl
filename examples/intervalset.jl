using SPPL
using BenchmarkTools
y1 = IntervalSet([
    0 .. 3,
    4 .. 6,
    7 .. 8
])
y2 = IntervalSet([
    @int("(0,2)"),
    @int("(2,3)"),
    @int("(3,10)")
])
y3 = IntervalSet([
    @int("(0,2]"),
    @int("[3,3]"),
    @int("[4,5)")
])
y4 = IntervalSet([
    @int("(0,1)"),
    @int("(4,5)")
])
y5 = IntervalSet([
    0 .. 1,
    5 .. 7
])

union(y1, y2)
