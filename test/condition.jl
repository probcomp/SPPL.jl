using SPPL
using Test
function test_condition_continuous_interval()
    i = IntervalLeaf(:x, Normal(0,1), -Inf..Inf, Dict(:x=>identity, :y=>exp, :z=>abs))
    @test condition(i,SolvedEvent(:x, -1.0..1.0)) == 0
end
function test_condition_continuous_intervalset()
end

@testset "condition" begin
    test_condition_continuous_interval()
    test_condition_continuous_intervalset()
    # test_condition_discrete_interval()
    # test_condition_discrete_intervalset()
end
