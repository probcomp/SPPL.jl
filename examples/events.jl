module Events
using SPPL

s1 = StringEvent(:y, Set(["a", "b", "c"]))
s2 = StringEvent(:x, Set(["a", "d", "e"]))
e = AndEvent([s1, s2])
assignments = Dict(:x=>"a", :z=>3, :y=>"b")
println(assignments in e)

end
