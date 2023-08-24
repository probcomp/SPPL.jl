function test_sqrt()
    @test preimage(sqrt, 2) == FiniteReal(Set([4]), true)
    @test preimage(sqrt, -1) == EMPTY_SET
    @test preimage(sqrt, -Inf .. Inf) == 0 .. Inf
    @test preimage(sqrt, 2 .. 5) == 4 .. 25
    @test preimage(sqrt, -1 .. 4) == 0 .. 16
    @test preimage(sqrt, Interval{Open,Closed}(3, 5)) == Interval{Open,Closed}(9, 25)
    @test preimage(sqrt, Interval{Open,Open}(3, 3)) == EMPTY_SET
    @test preimage(sqrt, Interval{Closed,Open}(-1, 0)) == EMPTY_SET
end

function test_log()
    @test_broken preimage(log, 0.0) ≈ FiniteReal(0.0)
    @test preimage(log, -Inf .. Inf) == 0 .. Inf
    @test preimage(log, -1.0 .. 1.0) ≈ 1 / ℯ .. ℯ
    @test preimage(log, 0 .. Inf) == 1 .. Inf
end
function test_abs()
    @test preimage(abs, -1.0) == EMPTY_SET
    @test preimage(abs, 0.0) == FiniteReal(0.0, b=true)
    @test preimage(abs, 1.0) == FiniteReal(-1.0, 1.0)
end

@testset "transforms" begin
    @test preimage(sqrt, EMPTY_SET) == EMPTY_SET
    test_sqrt()
    test_log()
    test_abs()
end
