function test_solved_events()
    e = SolvedEvent(:x, Interval(1, 5, true, false))
    @test e(Dict(:x => 2))
    @test !(e(Dict(:x => 5)))
    @test preimage(e, true) == Dict(:x => (Interval(1, 5, true, false)))
    @test preimage(e, false) == Dict(:x => 1)
end
function test_unsolved_events()
end

@testset "events" begin
    test_solved_events()
    test_unsolved_events()
end
