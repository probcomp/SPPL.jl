module IndianGPA

using SPPL

n = @sppl begin
    Nationality ~ SPPL.Choice([:India => 0.5, :USA => 0.5])
    if Nationality == :India
        Perfect ~ SPPL.Bernoulli(0.1)
        if Perfect == 1
            GPA ~ SPPL.Atomic(10)
        else
            GPA ~ SPPL.Uniform(0, 10)
        end
    else
        Perfect ~ SPPL.Bernoulli(0.15)
        if Perfect == 1
            GPA ~ SPPL.Atomic(4)
        else
            GPA ~ SPPL.Uniform(0, 4)
        end
    end
end

println(n.model.prob(n.Perfect << set(1)))
event = (n.Nationality << set(:USA)) & (n.GPA > 3) | ((8 < n.GPA) < 10)
model_condition = n.model.condition(event)

end # module
