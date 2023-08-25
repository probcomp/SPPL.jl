function test_solved_events()
    e = SolvedEvent(:x, Interval{Open,Closed}(1, 5))
    @test e(Dict(:x => 2))
    @test !e(Dict(:x => 1))
    @test preimage(e, true) == 0
    @test preimage(e, false) == 0
end
function test_unsolved_events()
end
@testset "events" begin
    test_solved_events()
    test_unsolved_events()
end
