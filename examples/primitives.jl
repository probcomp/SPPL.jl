module Primitives

include("../src/SPPL.jl")
using .SPPL

test_1 = () -> begin
    v1 = Id(:v1)
    v2 = Id(:v2)
    v3 = Id(:v3)

    command = Sequence(Sample(v1, SPPL.Choice([:you => 0.5, :no => 0.5])),
                       IfElse(v1 << set(:you),
                              Sequence(Sample(v2, SPPL.Bernoulli(0.15)),
                                       IfElse(v2 << set(1),
                                              Sample(v3, SPPL.Bernoulli(0.2)),
                                              true,
                                              Sample(v3, SPPL.Bernoulli(0.2)))),
                              true,
                              Sequence(Sample(v2, SPPL.Bernoulli(0.15)),
                                       IfElse(v2 << set(1),
                                              Sample(v3, SPPL.Bernoulli(0.2)),
                                              true,
                                              Sample(v3, SPPL.Bernoulli(0.2))))))

    model = command.interpret()
    println(model)
end

test_2 = () -> begin
    nationality = Id(:nationality)
    perfect = Id(:perfect)
    gpa = Id(:gpa)

    command = SPPL.Sequence(SPPL.Sample(nationality, SPPL.Choice([:India => 0.5, :USA => 0.5])), SPPL.IfElse(nationality << set(:India), SPPL.Sequence(SPPL.Sample(perfect, SPPL.Bernoulli(0.1)), SPPL.IfElse(perfect << set(1), SPPL.Sample(gpa, SPPL.Atomic(10)), true, SPPL.Sample(gpa, SPPL.Uniform(0, 10)))), true, SPPL.Sequence(SPPL.Sample(perfect, SPPL.Bernoulli(0.15)), SPPL.IfElse(perfect << set(1), SPPL.Sample(gpa, SPPL.Atomic(4)), true, SPPL.Sample(gpa, SPPL.Uniform(0, 4))))))

    model = command.interpret()
    println(model)
end

test_3 = () -> begin
    namespace = @sppl begin
        nationality ~ SPPL.Choice([:India => 0.5, :USA => 0.5])
        if nationality == :India
            perfect ~ SPPL.Bernoulli(0.1)
            perfect == 1 ? gpa ~ SPPL.Atomic(10) : gpa ~ SPPL.Uniform(0, 10)
        else
            perfect ~ SPPL.Bernoulli(0.15)
            perfect == 1 ? gpa ~ SPPL.Atomic(4) : gpa ~ SPPL.Uniform(0, 4)
        end
    end
    println(namespace.model)
end

test_4 = () -> begin
    namespace = @sppl begin
        nationality ~ SPPL.Choice([:India => 0.5, :USA => 0.5])
        if nationality == :India
            perfect ~ SPPL.Bernoulli(0.1)
            if perfect == 1
                gpa ~ SPPL.Atomic(10)
            else
                gpa ~ SPPL.Uniform(0, 10)
            end
        else
            perfect ~ SPPL.Bernoulli(0.15)

            # Commenting out the below should cause a MixtureError.

            #if perfect == 1
            #    gpa ~ SPPL.Atomic(4)
            #else
            #    gpa ~ SPPL.Uniform(0, 4)
            #end
        end
    end
    println(namespace.model)
end

test_1()
test_2()
test_3()

# Should error.
try
    test_4()
catch PyError
    println("Caught error. This is expected.")
end

end # module
