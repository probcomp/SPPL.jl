using SPPL

i = IntervalSet([0..1, 2..4, 6..8, 10..typemax(Int)])
j = IntervalSet(Interval{Int}[])
k = IntervalSet([-1..1, Interval(3,7.0, false, true), Interval(11, Inf, true, false)])
m = IntervalSet([-Inf..Inf])
n = IntervalSet([typemin(Int)..typemax(Int)])

ii = IntervalSet([i..(i+1) for i in 1:2:1000])
jj = IntervalSet([(i+1)..(i+2) for i in 1:2:1000])
kk = IntervalSet([Interval(i+1,i+2,false, false) for i in 1:2:100])

intersect(i,k)
intersect(i,j)

union(i,j)