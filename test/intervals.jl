import Intervals: Intervals
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

function test_finite_real()
    @test 1 in FiniteReal(Set([1, 2, 3]))
    @test !(2 in FiniteReal(Set([1])))
    @test 1 in FiniteReal(1)
    @test !(3 in FiniteReal(1, 2))
    @test FiniteReal(1, 2, 3) == FiniteReal(1, 2, 3)
    @test FiniteReal(1) != FiniteReal(2)
end

function test_concat()
    @test Concat(EMPTY_SET, FiniteReal(1), Interval(2 .. 5)) ==
          Concat(EMPTY_SET, FiniteReal(1), Interval(2 .. 5))
    f = Concat(FiniteNominal("a"), EMPTY_SET, Interval(1 .. 5))
    @test f != Concat(FiniteNominal("b"), EMPTY_SET, Interval(1 .. 5))
    @test "a" in f
    @test 2 in f
    @test !("b" in f)
end

function test_invert()
    @test invert(FiniteNominal("a", "b")) == FiniteNominal("a", "b"; b=false)
    @test invert(FiniteReal(1)) == 0
    @test invert(Interval(1 .. 5)) == Interval(Intervals.IntervalSet([
        Intervals.Interval{Closed,Open}(-Inf, 1),
        Intervals.Interval{Open,Closed}(5, Inf)]))
end

function test_complement()
    @test complement(EMPTY_SET) == Concat(FiniteNominal(; b=false), EMPTY_SET, Interval(-Inf .. Inf))
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
end

function test_intersect()
    @test EMPTY_SET ∩ EMPTY_SET == EMPTY_SET
    @test EMPTY_SET ∩ Interval(1 .. 5) == EMPTY_SET
    @test Interval(1 .. 5) ∩ EMPTY_SET == EMPTY_SET

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
end

function test_cross_union()
end
function test_cross_intersect()
end

@testset "intervals" begin
    test_empty()
    test_finite_nominal()
    test_finite_real()
    test_concat()
    test_intersect()
    test_union()
    test_invert()
    test_complement()
    # test_cross_union()
    # test_cross_intersect()
end
