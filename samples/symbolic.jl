using SymbolicUtils
using Symbolics
using MacroTools

function parse_transform(ex, constants, variables)
    formula = eval(substitute_constants(ex, constants, variables))
    transformation = simplify(formula, rewriter=SIMPLIFICATION_RULES)
end

const SIMPLIFICATION_RULES = Symbolics.Chain([
    @rule log(exp(~x)) => ~x
    @acrule log(exp(~x))+~y => ~x+~y

    @rule sqrt((~x)^2) => abs(~x)
    @acrule sqrt((~x)^2)+~y => abs(~x)+~y
])

substitute_constants(ex, constants, variables) = return MacroTools.postwalk(sub_func(constants, variables), ex)

function sub_func(constants, variables)
    function substitute(ex)
        if ex isa Symbol 
            if haskey(constants, ex)
                return get(constants, ex, ex)
            elseif haskey(variables, ex)
                return get(variables, ex, ex)
            end
            return ex
        else
            return ex
        end
    end
end

val = foo()
function foo()
    constants = Dict{Symbol, Any}(
        :a=>1
    )
    symbols = [:X, :Y, :Z]
    vars = [(@variables $(sym))[1] for sym in symbols]
    variables = Dict(zip(symbols, vars))

    # ex = :(log(exp(X+a+a)))
    ex = :(sqrt(X^2)+Y)
    parse_transform(ex, constants, variables)
end


@variables x
rlogexp = @rule log(exp(~x)) => ~x
rlogexp2 = @acrule log(exp(~x))+~y => ~x+~y
simplify(log(exp(x+3))+5, rewriter=rlogexp2) 

@syms a::Real b::Real

logexp = @rule log(exp(~x)) => ~x
logexp2 = @acrule log(exp(~x))+~y => ~x + ~y
logexp_rules = Symbolics.Chain([logexp, logexp2])

simplify(log(exp(a+3))+5, rewriter=logexp_rules)
# logexp(log(exp(a+3))-5, )
# logexp2(log(exp(log(a)+3))-4)