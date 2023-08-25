function test_finite_nominal()
    @test :x in FiniteNominal(Set([:x]), true)
    @test !(:y in FiniteNominal(Set([:x]), true))
    @test !(:x in FiniteNominal(:x, b=false))
    @test :y in FiniteNominal(:x, b=false)
end

function test_finite_real()
    @test 1 in FiniteReal(Set([1, 2, 3]), true)
    @test !(2 in FiniteReal(Set([1]), true))
    @test !(1 in FiniteReal(1, b=false))
    @test 3 in FiniteReal(1, 2, b=false)
end

function test_interval()
    @test Interval(2, 3) == Interval(2, 3) == Interval(3, 2) == 2 .. 3 ==
          Interval{Closed,Closed,Int,Int}(2, 3)
    @test Interval(2, 3) != Interval(2, 5)
    @test Interval{Open,Closed}(2, 3) != Interval{Closed,Closed}(2, 3)
    @test Interval{Open,Closed}(2, 3) == Interval{Open,Closed}(2, 3)
    @test Interval{Unbounded,Open}(-Inf, 2) != Interval{Unbounded,Closed}(-Inf, 2)
    @test Interval{Open,Open}(2, 3.0) == Interval{Open,Open,Int,Float64}(2, 3.0)
    @test Interval{Open,Unbounded}(2, Inf) == Interval{Open,Unbounded,Int,Float64}(2, Inf)
    @test Interval{Closed,Open}(2, 2) == Interval{Open,Open}(2, 2) ==
          Interval{Open,Closed}(2, 2.0) == EMPTY_SET
    @test_throws Exception Interval{Closed,Closed}(2, Inf)
    @test_throws Exception Interval{Open,Closed}(-Inf, 2)
end

function test_complement()
    @test complement(FiniteNominal(:x, :y, :z; b=true)) == FiniteNominal(:x, :y, :z; b=false)
    @test_broken complement(FiniteReal(1, 2, 3; b=true)) == "what"
    @test_broken complement(EMPTY_SET) == -Inf .. Inf # -Inf .. Inf ∪ nominal universe?
    @test complement(-Inf .. Inf) == EMPTY_SET
    @test complement(-Inf .. 2) == Interval{Open,Unbounded}(2, Inf)
    @test_broken complement(2 .. 3) == 1 .. 4
    @test_broken complement(Interval{Closed,Open}(-1, 1)) == 1 .. 4
end

function test_union()
    @test EMPTY_SET ∪ (1 .. 5) == 1 .. 5

    @test FiniteNominal("a") ∪ FiniteNominal("b") == FiniteNominal("a", "b")
    @test FiniteNominal("a"; b=false) ∪ FiniteNominal("b"; b=false) ==
          FiniteNominal("a", "b"; b=false)
    @test FiniteNominal("a") ∪ FiniteNominal("b"; b=false) == 0

    @test (-Inf .. Inf) ∪ (1 .. 5) == -Inf .. Inf
    @test (-1 .. 1) ∪ (-2 .. 2) == -2 .. 2
    @test (0 .. 2) ∪ (1 .. 3) == (0 .. 3)
    @test (-Inf .. 2) ∪ (1 .. Inf) == -Inf .. Inf
    @test_broken Interval{Closed,Open}(-1, 0) ∪ Interval{Open,Closed}(0, 1) == 0
    @test (-Inf .. 2) ∪ Interval{Open,Closed}(2, 3) == -Inf .. 3
end

function test_intersect()
    set1 = FiniteNominal("a", "b", "c")
    set2 = FiniteNominal("d", "a", "c")
    set3 = FiniteNominal("e"; b=false)
    set4 = FiniteNominal("a", "e", b=false)
    @test intersect(set1, set2) == FiniteNominal("a", "c")
    @test intersect(set1, set3) == FiniteNominal("a", "b", "c")
    @test intersect(set4, set1) == FiniteNominal("b", "c")
    @test intersect(set3, set4) == FiniteNominal("e"; b=false)

    @test EMPTY_SET ∩ (1 .. 5) == EMPTY_SET
    @test (-Inf .. Inf) ∩ (1 .. 5) == 1 .. 5
    @test (1 .. 5) ∩ (3 .. 6) == 3 .. 5
    @test (1 .. Inf) ∩ (2 .. Inf) == 2 .. Inf
    @test Interval{Closed,Open}(0, 1) ∩ Interval{Open,Closed}(1, 2) == EMPTY_SET
    @test Interval{Open,Open}(0, 1) ∩ (0 .. Inf) == Interval{Open,Open}(0, 1)
    @test (-Inf .. Inf) ∩ Interval{Open,Closed}(-1, 1) == Interval{Open,Closed}(-1, 1)
    @test (1 .. 4) ∩ Interval{Open,Open}(2, 5) == Interval{Open,Closed}(2, 4)
end

function test_cross_union()
end
function test_cross_intersect()
end

@testset "intervals" begin
    test_finite_nominal()
    test_finite_real()
    test_complement()
    test_union()
    test_interval()
    test_intersect()
    test_cross_union()
    test_cross_intersect()
end
