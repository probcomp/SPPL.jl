using SPPL

i = IntervalSet(
    [
        Interval(0,1,true,false), 
        2..3, 
        4..4, 
        Interval(5,6,true,false), 
        Interval(6,7,false,true),
        Interval(8, typemax(Int), true, true)
    ]
)

complement(i)
macro joe(ex)
    dump(ex)
    ex
end
@joe log