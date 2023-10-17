using SPPL

i = IntervalSet([0..1, 2..4, 6..8, 10..Inf])
j = IntervalSet(Interval{Int}[])
k = IntervalSet([-1..1, Interval(3,7.0, false, true), Interval(11, Inf, true, false)])
m = IntervalSet([-Inf..Inf])
n = IntervalSet([typemin(Int)..typemax(Int)])

ii = IntervalSet([i..(i+1) for i in 1:2:100])
jj = IntervalSet([Interval(i+1,i+2,false, false) for i in 1:2:100])

a = Interval(typemin(Int),typemax(Int), true, true)
b = Interval(-Inf,Inf, true, false)

union(i,j)