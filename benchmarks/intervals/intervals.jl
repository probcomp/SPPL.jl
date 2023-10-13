using SPPL
using BenchmarkTools
x = 2 .. 4
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
# union(x, y1)
# union(x, y2)
# union(x, y3)
# union(x, y4)
# union(x, y5)
intersect(x, y1)
intersect(x, y2)
intersect(x, y3)
intersect(x, y4)
intersect(x, y5)

# x = @int "(1,2)"
# y5 = IntervalSet([
#     @int("(0,1)"),
#     @int("(1,3)")
# ])
# union(x, y5)
intersect(y1, y2)
