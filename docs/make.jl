using Documenter, SPPL

makedocs(modules=[SPPL],
         sitename="SPPL",
         authors="McCoy R. Becker and other contributors",
         pages=["API Documentation" => "index.md"])

deploydocs(repo = "github.com/probcomp/SPPL.jl.git")
