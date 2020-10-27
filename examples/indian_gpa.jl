module IndianGPA

include("../src/SPPL.jl")
using .SPPL

test_string_macro = () -> begin
spn = sppl"""
Nationality   ~= choice({'India': 0.5, 'USA': 0.5})
if (Nationality == 'India'):
    Perfect       ~= bernoulli(p=0.10)
    if (Perfect == 1):  
        GPA ~= atomic(loc=10)
    else:               
        GPA ~= uniform(loc=0, scale=10)
else:
    Perfect       ~= bernoulli(p=0.15)
    if (Perfect == 1):  
        GPA ~= atomic(loc=4)
    else:               
        GPA ~= uniform(loc=0, scale=4)
"""
println(spn)
end

test_native_macro_1 = () -> begin
    spn = @sppl begin
        nationality ~ SPPL.Choice([:India => 0.5, :USA => 0.5])
        perfect ~ SPPL.Bernoulli(0.1)
        gpa ~ SPPL.Atomic(4)
    end
    println(spn)
end

test_native_macro_2 = () -> begin
    spn = @sppl begin
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
            if perfect == 1
                gpa ~ SPPL.Atomic(4)
            else
                gpa ~ SPPL.Uniform(0, 4)
            end
        end
    end
end

@sppl function foo(x::Float64)
    nationality ~ SPPL.Choice([:India => x, :USA => 0.5])
    perfect ~ SPPL.Bernoulli(0.1)
    gpa ~ SPPL.Atomic(4)
end

test_string_macro()
test_native_macro_1()
#test_native_macro_2()
md = foo(0.5)
println(md)

end # module
