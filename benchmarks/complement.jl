using SPPL
int = IntervalSet(0..1, 2..3, @int("(4,5)"), @int("(5,7)"))
ent = IntervalSet(0..1, 2..3, @int("(4,5)"), @int("(5,7)"))

# a,b = invert(int)
# a
# b
intersect(int, ent)

int = IntervalSet(0..1, 2..3, @int("(4,5)"), @int("(5,7)"))
ent = IntervalSet(-3..(-2), -1..0, @int("(3,5)"), @int("(6,8)"))
intersect(int, ent)


int = IntervalSet(0..1, 4..5, @int("(6,7)"), @int("(8,9)"))
ent = IntervalSet(-3..(-2), 1.5..1.9, @int("(7,8)"))
intersect(int, ent)


int = IntervalSet(-Inf..1.0, @int("(5,Inf]"))
invert(int)

int = IntervalSet{Interval{Float64}}(Interval{Float64}[Interval(-Inf, 1.0, true, false), Interval(5.0, Inf, false, true)], 0x0000)