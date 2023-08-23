module Compiler
using SPPL
ex = @macroexpand @sppl function f()
    theta = 0.5
    x ~ bernoulli(theta)
    if x == 0
        z ~ bernoulli(0.1)
    elseif x > 0
        z ~ bernoulli(0.3)
    end
end
display(ex)


end
