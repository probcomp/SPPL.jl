function test_nominal()
    f = FiniteNominal("a")
    ff = FiniteNominal("b"; b=false)
    @test preimage(identity, f) == f
    @test preimage(log, f) == EMPTY_SET
    @test preimage(identity, ff) == ff
    @test preimage(log, ff) == EMPTY_SET
end
function test_sqrt()
    @test preimage(sqrt, 2) == FiniteReal(Set([4]), true)
    @test preimage(sqrt, -1) == EMPTY_SET
    @test preimage(sqrt, -Inf .. Inf) == SPPL.Interval(0 .. Inf)
    @test preimage(sqrt, 2 .. 5) == Interval(4 .. 25)
    @test preimage(sqrt, -1 .. 4) == Interval(0 .. 16)
    @test preimage(sqrt, Interval{Open,Closed}(3, 5)) == IntervalSet(Interval{Open,Closed}(9, 25))
    @test preimage(sqrt, Interval{Closed,Open}(-1, 0)) == EMPTY_SET
end

function test_log()
    @test preimage(log, 0.0) == FiniteReal(1.0)
    @test preimage(log, -Inf .. Inf) == 0 .. Inf
    @test preimage(log, -1.0 .. 1.0) == 1 / ℯ .. ℯ
    @test preimage(log, 0 .. Inf) == 1 .. Inf
end
function test_abs()
    @test preimage(abs, -1.0) == EMPTY_SET
    @test preimage(abs, 0.0) == FiniteReal(0.0, b=true)
    @test preimage(abs, 1.0) == FiniteReal(-1.0, 1.0)
    @test preimage(abs, -1.0 .. 3.0) == IntervalSet(-3.0 .. 3.0)
    @test preimage(abs, -Inf .. Inf) == IntervalSet(-Inf .. Inf)
    @test preimage(abs, 2 .. 3) == IntervalSet([-3 .. (-2), 2 .. 3])
    @test preimage(abs, Interval{Open,Open}(-1, 1)) == IntervalSet(Interval{Open,Open}(-1, 1))
    @test preimage(abs, Interval{Open,Open}(1, 2)) ==
          IntervalSet([Interval{Open,Open}(-2, -1), Interval{Open,Open}(1, 2)])
end

@testset "transforms" begin
    test_nominal()
    test_sqrt()
    test_log()
    test_abs()
end
