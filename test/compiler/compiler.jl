using SPPL
using Test

function test_assignment()
    code = quote
    a = 2
    b = [[1,2],[3,4]]
    # c = a*a
    end
    program = SPPL.compile(code)
    expected = Dict{Symbol, Any}(
        :a => 2,
        :b => [[1,2],[3,4]],
        # :c => 4
    )

    for (k, v) in program.constants
        @test v == expected[k]
    end
    for (k, v) in expected
        @test v == program.constants[k]
    end
end

@testset "parser" begin
    test_assignment()
end
