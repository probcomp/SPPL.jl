function test_sqrt()
    @test preimage(sqrt, 2) == 4
    @test preimage(sqrt, -1) == EMPTY_SET
    @test preimage(sqrt, Interval(nothing, nothing)) == Interval{Closed,Intervals.Unbounded}(0, nothing)
    @test preimage(sqrt, 2 .. 5) == 4 .. 25
    @test preimage(sqrt, -1 .. 4) == 0 .. 16
    @test preimage(sqrt, Interval{Open,Closed}(3, 5)) == Interval{Open,Closed}(9, 25)
    @test preimage(sqrt, Interval{Open,Open}(3, 3)) == EMPTY_SET
    @test preimage(sqrt, Interval{Closed,Open}(-1, 0)) == EMPTY_SET
end

function test_log()
    @test preimage(log, 1.0) ≈ ℯ
    @test preimage(log, Interval(nothing, nothing)) == Interval(nothing, nothing)
    @test preimage(log, Interval(-1.0, 1.0)) == Interval(1 / ℯ, ℯ)
end
function test_abs()
    @test preimage(abs, 0.0) == 0.0
    @test preimage(abs, 1.0) == (-1, 1)
    @test preimage(abs, -1.0) == EMPTY_SET
end

@testset "transforms" begin
    @test preimage(sqrt, EMPTY_SET) == EMPTY_SET
    test_sqrt()
    test_log()
    test_abs()
end
