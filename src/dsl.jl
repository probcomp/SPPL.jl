function parse_block(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    for ex in expr.args
        new = MacroTools.postwalk(ex) do e
            if @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ -> d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Transform), v, d)

            elseif @capture(e, v_ == d_)
                Expr(:call, :(<<), v, Expr(:call, GlobalRef(SPPL, :set), d))

            elseif @capture(e, if cond_ body1__ else body2__ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            elseif @capture(e, cond_ ? body1__ : body2__)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            else
                e

            end
        end
        push!(commands, new)
    end

    emit = Expr(:block, values(variable_declarations)...,
                Expr(:(=), :command, Expr(:call, GlobalRef(SPPL, :Sequence), commands...)),
                quote model = command.interpret() end,
                Expr(:(=), :namespace, Expr(:tuple, namespace..., Expr(:(=), :model, :model))),
                quote namespace end)

    emit = MacroTools.postwalk(rmlines ∘ unblock, emit)
    emit
end

function parse_function(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    @capture(expr, function fn_(args__) body__ end)
    for ex in body
        new = MacroTools.postwalk(ex) do e
            if @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ -> d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Transform), v, d)

            elseif @capture(e, v_ == d_)
                Expr(:call, :(<<), v, Expr(:call, GlobalRef(SPPL, :set), d))

            elseif @capture(e, if cond_ body1_ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, body1)

            elseif @capture(e, if cond_ body1__ else body2__ end)
                Expr(:call, GlobalRef(SPPL, :IfElse), cond, 
                     length(body1) == 1 ? body1[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body1...), 
                     true, 
                     length(body2) == 1 ? body2[1] : Expr(:call, GlobalRef(SPPL, :Sequence), body2...))

            else
                e
            end
        end
        push!(commands, new)
    end

    new_body = Expr(:block, values(variable_declarations)...,
                    Expr(:(=), :command, Expr(:call, GlobalRef(SPPL, :Sequence), commands...)),
                    quote model = command.interpret() end,
                    Expr(:(=), :namespace, Expr(:tuple, namespace..., Expr(:(=), :model, :model))),
                    quote namespace end)

    emit = quote function $fn($(args...))
            $new_body
        end
    end
    MacroTools.postwalk(rmlines ∘ unblock, emit)
end

function _sppl(expr::Expr)
    expr.head == :block && return parse_block(expr)
    expr.head == :function && return parse_function(expr)
    error("ParseError (@sppl): requires a block or a long-form function definition.")
end

macro sppl(expr)
    new = _sppl(expr)
    esc(new)
end

macro sppl_str(str)
    compiler(str).execute_module()
end
