<img src="sppl.png" style="display:block;margin-right:auto;margin-left:auto;width:30%;">

A small DSL for programming `sppl` across [PyCall.jl](https://github.com/JuliaPy/PyCall.jl).

Allows the usage of direct string macros:

```julia
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
```

```
PyObject <sppl.spn.SumSPN object at 0x7f306382fd30>
```

as well as the usage of a native macro with native structures:

```julia
spn = @sppl begin
    nationality ~ SPPL.Choice([:India => 0.5, :USA => 0.5])
    perfect ~ SPPL.Bernoulli(0.1)
    gpa ~ SPPL.Atomic(4)
end
println(spn)
```

```
PyObject <sppl.spn.ProductSPN object at 0x7f306381f820>
```

Of course, you can use native abstractions:

```julia
@sppl function foo(x::Float64)
    nationality ~ SPPL.Choice([:India => x, :USA => 0.5])
    perfect ~ SPPL.Bernoulli(0.1)
    gpa ~ SPPL.Atomic(4)
end
```

which expands to produce a generator:

```
:(function foo(x::Float64)
      gpa = Main.IndianGPA.SPPL.Id(:gpa)
      nationality = Main.IndianGPA.SPPL.Id(:nationality)
      perfect = Main.IndianGPA.SPPL.Id(:perfect)
      command = Sequence(foo(x::Float64), begin
                  Main.IndianGPA.SPPL.Sample(nationality, SPPL.Choice([:India => x, :USA => 0.5]))
                  Main.IndianGPA.SPPL.Sample(perfect, SPPL.Bernoulli(0.1))
                  Main.IndianGPA.SPPL.Sample(gpa, SPPL.Atomic(4))
              end)
      model = command.interpret()
      model
  end)
```
