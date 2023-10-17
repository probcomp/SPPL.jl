using SPPL
using BenchmarkTools

e = SolvedEvent(:x, -1.0..1.0)
f = SolvedEvent(:a, -1.0..1.0)
g = SolvedEvent(:x, 2.0..3.0)
h = SolvedEvent(:x, -3.0..(-2.0))
i = UnsolvedEvent(:a, -1..2.0, exp)
j = UnsolvedEvent(:a, 0..1.0, exp)

E = (e∩f) ∪ (g∩h∩i)
dnf(E)
F = (e∪f) ∩ (g ∪ h ∪ i)
dnf(F)


using ReverseDiff
function foo(x)
    x = x.^2
    if sum(x) < 0
        sum(x)^2
    else
        sum(sqrt.(x))
    end
end
x = rand(10000)
@btime foo($x)
# ReverseDiff.gradient(foo, x)
@btime ReverseDiff.gradient(foo,$x)