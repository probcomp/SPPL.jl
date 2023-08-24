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
    @test Interval(2, 3) == Interval(3, 2) == 2 .. 3 == Interval{Closed,Closed,Int,Int}(2, 3)
    @test Interval{Open,Open}(2, 3.0) == Interval{Open,Open,Int,Float64}(2, 3.0)
    @test Interval{Open,Unbounded}(2, Inf) == Interval{Open,Unbounded,Int,Float64}(2, Inf)
    @test Interval{Closed,Open}(2, 2) == Interval{Open,Open}(2, 2) == Interval{Open,Closed}(2, 2.0) == EMPTY_SET
    @test_throws Exception Interval{Closed,Closed}(2, Inf)
    @test_throws Exception Interval{Open,Closed}(-Inf, 2)
end

function test_union()
end

function test_intersection()
end

function test_complement()
end
@testset "intervals" begin
    test_finite_nominal()
    test_finite_real()
    test_interval()
end
