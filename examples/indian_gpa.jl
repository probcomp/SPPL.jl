module IndianGPA

include("../src/SPPL.jl")
using .SPPL

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

spn = @sppl begin
    nationality ~ SPPL.Choice([:India => 0.5, :USA => 0.5])
    if nationality == :India
        perfect ~ SPPL.Bernoulli(0.1)
        if perfect == 1
            gpa ~ SPPL.Atomic(4)
        else
            gpa ~ SPPL.Uniform(0, 4)
        end
    end
end

println(spn.interpret())

end # module
