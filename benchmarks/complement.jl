using SPPL
int = IntervalSet(0..1, 2..3, @int("(4,5)"), @int("(5,7)"))
invert(int)