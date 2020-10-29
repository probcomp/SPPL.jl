function parse_block(expr::Expr)
    commands = Any[]
    array_declarations = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    for ex in expr.args
        new = MacroTools.postwalk(ex) do e

            if @capture(e, v_[a_] ~ d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Sample), quote $v[$a] end, d)

            elseif @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ = array(n_))
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), 3)))
                end
                e = Expr(:noop)

            elseif @capture(e, v_[a_] .> d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Transform), quote $v[$a] end, d)

            elseif @capture(e, v_ .> d_)
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

            elseif @capture(e, for ind_ in stx_ : endx_ body_ end)
                Expr(:call, GlobalRef(SPPL, :For), stx, endx, Expr(:->, ind, body)) 

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

    # Filter commands to remove :noop expressions caused by array declarations.
    commands = filter(commands) do expr
        expr isa Expr && expr.head != :noop
    end

    emit = Expr(:block, values(variable_declarations)...,
                Expr(:(=), :command, Expr(:call, GlobalRef(SPPL, :Sequence), commands...)),
                quote model = command.interpret() end,
                Expr(:(=), :namespace, Expr(:tuple, namespace..., Expr(:(=), :model, :model))),
                quote namespace end)

    emit = MacroTools.postwalk(rmlines ∘ unblock, emit)
    emit
end

function parse_longform_function(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    @capture(expr, function fn_(args__) body__ end) || error("ParseError (parse_function): parsing took invalid branch (syntax match failure).")
    for ex in body
        new = MacroTools.postwalk(ex) do e

            if @capture(e, v_[a_] ~ d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Sample), quote $v[$a] end, d)

            elseif @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ = array(n_))
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), 3)))
                end
                e = Expr(:noop)

            elseif @capture(e, v_[a_] .> d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Transform), quote $v[$a] end, d)

            elseif @capture(e, v_ .> d_)
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

            elseif @capture(e, for ind_ in stx_ : endx_ body_ end)
                Expr(:call, GlobalRef(SPPL, :For), stx, endx, Expr(:->, ind, body)) 

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

    # Transformed body of method.
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

function parse_anonymous_function(expr::Expr)
    commands = Any[]
    variable_declarations = Dict()
    namespace = Any[]
    @capture(expr, (args__) -> body__) || error("ParseError (parse_anonymous_function): parsing took invalid branch (syntax match failure).")
    for ex in body
        new = MacroTools.postwalk(ex) do e

            if @capture(e, v_[a_] ~ d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Sample), quote $v[$a] end, d)

            elseif @capture(e, v_ ~ d_)
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v)))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :Id), QuoteNode(v))))
                end
                e = Expr(:call, GlobalRef(SPPL, :Sample), v, d)

            elseif @capture(e, v_ = array(n_))
                !(v in keys(variable_declarations)) && begin
                    variable_declarations[v] = Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), n))
                    push!(namespace, Expr(:(=), v, Expr(:call, GlobalRef(SPPL, :IdArray), QuoteNode(v), 3)))
                end
                e = Expr(:noop)

            elseif @capture(e, v_[a_] .> d_)
                !(v in keys(variable_declarations)) && error("ParseError (parse_block): IdArray must be declared before use.")
                e = Expr(:call, GlobalRef(SPPL, :Transform), quote $v[$a] end, d)

            elseif @capture(e, v_ .> d_)
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

            elseif @capture(e, for ind_ in stx_ : endx_ body_ end)
                Expr(:call, GlobalRef(SPPL, :For), stx, endx, Expr(:->, ind, body)) 

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

    # Transformed body of method.
    new_body = Expr(:block, values(variable_declarations)...,
                    Expr(:(=), :command, Expr(:call, GlobalRef(SPPL, :Sequence), commands...)),
                    quote model = command.interpret() end,
                    Expr(:(=), :namespace, Expr(:tuple, namespace..., Expr(:(=), :model, :model))),
                    quote namespace end)

    emit = Expr(:->, Expr(:tuple, args...), new_body)
    MacroTools.postwalk(rmlines ∘ unblock, emit)
end

function _sppl(expr::Expr)
    expr.head == :block && return parse_block(expr)
    expr.head == :function && return parse_longform_function(expr)
    expr.head == :-> && return parse_anonymous_function(expr)
    error("ParseError (@sppl): requires a block or a long-form function definition.")
end

# ------------ Macros ------------ #

macro sppl(expr)
    new = _sppl(expr)
    esc(new)
end

macro sppl(debug, expr)
    new = _sppl(expr)
    debug == :debug && println(new)
    esc(new)
end

# String macro.
macro sppl_str(debug_flag, str)
    comp = compiler(str)
    debug_flag == :debug && println(comp.render_module())
    comp.execute_module()
end

macro sppl_str(str)
    compiler(str).execute_module()
end
