module SimpleSwitch

using SPPL

namespace = @sppl begin
    Y ~ RandInt(0, 4)
    Switch(Y, 0 : 4) do k
        X ~ Bernoulli(1 / (1 + k))
    end
end

namespace.model.logprob(namespace.X << set(1))

end # module
