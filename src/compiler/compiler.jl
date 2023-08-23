using MacroTools
macro sppl(ex)
    ex = MacroTools.longdef(ex)
    # if ex.head != :function
    #     error("ex is not function")
    # end
    parse_sppl_function(ex)
end

function parse_sppl_function(ex)
    desugar_tildes(ex)
end

function desugar_tildes(expr) # from Gen.jl repo
    MacroTools.postwalk(expr) do e
        # Replace tilde statements with :gentrace expressions
        if MacroTools.@capture(e, lhs_Symbol ~ rhs_call)
            addr = QuoteNode(lhs)
            Expr(:(=), lhs, Expr(:sppl_at, rhs))
        elseif MacroTools.@capture(e, lhs_ ~ rhs_call)
            error("Syntax error: Invalid left-hand side: $(e)." *
                  "Only a variable or address can appear on the left of a `~`.")
        elseif MacroTools.@capture(e, lhs_ ~ rhs_)
            error("Syntax error: Invalid right-hand side in: $(e)")
        else
            e
        end
    end
end
export @sppl
