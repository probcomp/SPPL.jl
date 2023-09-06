function test_empty()
    @test EMPTY_SET == EMPTY_SET
end

function test_finite_nominal()
    @test FiniteNominal(Set{String}(), true) == EMPTY_SET
    @test "a" in FiniteNominal(Set(["a"]), true)
    @test !("x" in FiniteNominal("x", b=false))
    @test "y" in FiniteNominal("x", b=false)
    @test FiniteNominal("a"; b=false) == FiniteNominal("a"; b=false)
end

function test_interval()
    @test Interval(1, 1, true, true) == Interval(1, 1, true, true)
    @test Interval(1, 2, true, true) != Interval(1, 2, true, false)
    @test Interval(1, 2, true, true) != Interval(1, 1, true, true)
    @test Interval(1, 1, true, false) == EMPTY_SET
    @test Interval(Inf, Inf, false, false) == EMPTY_SET

    # Convenience methods
    @test 1 .. 5 == Interval(1, 5, true, true)
end

function test_finite_real()
    @test 1 in FiniteReal([1, 2, 3])
    @test !(2 in FiniteReal([1]))
    @test 1 in FiniteReal(1)
    @test !(3 in FiniteReal(1, 2))
    @test FiniteReal(1, 2, 3) == FiniteReal(1, 2, 3)
    @test FiniteReal(1) != FiniteReal(2)
end

function test_concat()
    @test Concat(EMPTY_SET, FiniteReal(1), 2 .. 5) ==
          Concat(EMPTY_SET, FiniteReal(1), 2 .. 5)
    f = Concat(FiniteNominal("a"), EMPTY_SET, 1 .. 5)
    @test f != Concat(FiniteNominal("b"), EMPTY_SET, 1 .. 5)
    @test "a" in f
    @test 2 in f
    @test !("b" in f)
end

function test_invert()
    @test invert(FiniteNominal("a", "b")) == FiniteNominal("a", "b"; b=false)
    @test invert(FiniteReal(1)) == IntervalSet([
        (@int "[-Inf, 1)"),
        (@int "(1, Inf]")
    ])
    @test invert(FiniteReal(-1,1)) == IntervalSet([
        (@int "[-Inf,-1)"),
        (@int "(-1,1)"),
        (@int "(1,Inf]")
    ])
    @test invert(FiniteReal(Inf)) == @int("[-Inf,Inf)")
    @test invert(FiniteReal(-Inf)) == @int("(-Inf,Inf]")
    @test invert(FiniteReal(-Inf, Inf)) == @int "(-Inf, Inf)"
    @test invert(FiniteReal(3,Inf)) == IntervalSet([
        (@int "[-Inf, 3)"),
        (@int "(3,Inf)")
    ])

    @test invert(1 .. 5) == IntervalSet([
        (@int "[-Inf, 1)"),
        (@int "(5,Inf]")
    ])
    @test invert(1 .. Inf) == @int ("[-Inf, 1)")
    @test invert(-Inf..Inf) == EMPTY_SET
    @test_skip invert(@int("(-Inf,Inf)")) == FiniteReal(-Inf,Inf)

end

function test_complement()
    @test complement(EMPTY_SET) == Concat(FiniteNominal(; b=false), EMPTY_SET, -Inf .. Inf)
    # @test complement(FiniteNominal(:x, :y, :z; b=true)) == FiniteNominal(:x, :y, :z; b=false)
    # @test complement(FiniteReal(1, 2, 3; b=true)) == FiniteReal(1, 2, 3; b=false)
    # @test complement(-Inf .. Inf) == IntervalSet()
    # @test complement(-Inf .. 2) == IntervalSet(Interval{Open,Closed}(2, Inf))
    # @test complement(Interval{Closed,Open}(2, 3)) == IntervalSet([Interval{Closed,Open}(-Inf, 2), Interval{Closed,Closed}(3, Inf)])
end

function test_union()
    @test EMPTY_SET ∪ EMPTY_SET == EMPTY_SET
    @test EMPTY_SET ∪ FiniteNominal("a") == FiniteNominal("a")
    @test FiniteNominal("a") ∪ EMPTY_SET == FiniteNominal("a")

    @test FiniteNominal("a") ∪ FiniteNominal("b") == FiniteNominal("a", "b")
    @test FiniteNominal("a"; b=false) ∪ FiniteNominal("b"; b=false) ==
          FiniteNominal(; b=false)
    @test FiniteNominal("a", "c") ∪ FiniteNominal("b", "a"; b=false) ==
          FiniteNominal("b"; b=false)

    set1 = FiniteNominal("a", "b", "c")
    set2 = FiniteNominal("d", "a", "c")
    set3 = FiniteNominal("e"; b=false)
    @test union(set1, set2, set3) == union(set1, set3, set2) ==
          union(set2, set1, set3) == union(set2, set3, set1) ==
          union(set3, set1, set2) == union(set3, set2, set1) ==
          FiniteNominal("e"; b=false)

    # Intervals
    @test union(1 .. 7, 2 .. 5) == union(1 .. 5, 2 .. 7) == 1 .. 7
    @test union(0 .. 1, Interval(1, 2, false, false)) == Interval(0, 2, true, false)
    @test union(0 .. 1, 2 .. 3) == IntervalSet([0 .. 1, 2 .. 3])
    @test union(Interval(0, 1, false, false), Interval(1, 2, false, false)) == IntervalSet([
        Interval(0, 1, false, false),
        Interval(1, 2, false, false)
    ])
end

function test_intersect()
    @test EMPTY_SET ∩ EMPTY_SET == EMPTY_SET
    @test EMPTY_SET ∩ (1 .. 5) == EMPTY_SET
    @test (1 .. 5) ∩ EMPTY_SET == EMPTY_SET

    set1 = FiniteNominal("a", "b", "c")
    set2 = FiniteNominal("d", "a", "c")
    set3 = FiniteNominal("e"; b=false)
    set4 = FiniteNominal("a", "e", b=false)
    @test intersect(set1, set2) == FiniteNominal("a", "c")
    @test intersect(set1, set3) == FiniteNominal("a", "b", "c")
    @test intersect(set4, set1) == FiniteNominal("b", "c")
    @test intersect(set3, set4) == FiniteNominal("e"; b=false)

    set1 = FiniteNominal("a", "b", "c")
    set2 = FiniteNominal("b", "c", "d")
    set3 = FiniteNominal("c", "d", "e")
    @test intersect(set1, set2, set3) == FiniteNominal("c")

    # Intervals
    @test intersect(0 .. 4, 2 .. 3) == 2 .. 3
    @test intersect(0 .. 4, Interval(2, 3, false, true)) == Interval(2, 3, false, true)
    @test intersect(0 .. 1, 2 .. 3) == EMPTY_SET
    @test intersect(0 .. 1, Interval(1, 2, false, true)) == EMPTY_SET
end

function test_cross_union()
end
function test_cross_intersect()
end

@testset "intervals" begin
    test_empty()
    test_finite_nominal()
    test_finite_real()
    test_interval()
    test_concat()
    test_intersect()
    test_union()
    test_invert()
    # test_complement()
    # test_cross_union()
    # test_cross_intersect()
end
