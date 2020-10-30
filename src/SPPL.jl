module SPPL

using Conda
using MacroTools
using MacroTools: @capture, rmlines, unblock
using PyCall

# Install ProbLog.
if PyCall.conda
    Conda.add("pip")
    pip = joinpath(Conda.BINDIR, "pip")
    run(`$pip install sppl`)
else
    try
        pyimport("sppl")
        pyimport("sppl.compilers")
    catch ee
        typeof(ee) <: PyCall.PyError || rethrow(ee)
        warn("""
             Python Dependencies not installed
             Please either:
             - Rebuild PyCall to use Conda, by running in the julia REPL:
             - `ENV[PYTHON]=""; Pkg.build("PyCall"); Pkg.build("Problox")`
             - Or install the depencences, eg by running pip
             - `pip install sppl`
             """
             )
    end
end

# ------------ Precompile compatibility ------------ #

const fractions = PyNULL()
const sppl = PyNULL()
const dists = PyNULL()
const ast_compiler = PyNULL()
const sppl_compiler = PyNULL()
const transforms = PyNULL()
const sym_util = PyNULL()
const dnf = PyNULL()
const compiler = PyNULL()
const Id = PyNULL()
const IdArray = PyNULL()
const Skip = PyNULL()
const Sample = PyNULL()
const Transform = PyNULL()
const Cond = PyNULL()
const IfElse = PyNULL()
const For = PyNULL()
const Switch = PyNULL()
const Sequence = PyNULL()
const dnf_to_disjoint_union = PyNULL()
const binspace = PyNULL()
const Fraction = PyNULL()
const Sqrt = PyNULL()

function __init__()

    # ------------ Imports ------------ #

    copy!(fractions, pyimport("fractions"))
    copy!(sppl, pyimport("sppl"))
    copy!(dists, pyimport("sppl.distributions"))
    copy!(ast_compiler, pyimport("sppl.compilers.ast_to_spn"))
    copy!(sppl_compiler, pyimport("sppl.compilers.sppl_to_python"))
    copy!(transforms, pyimport("sppl.transforms"))
    copy!(sym_util, pyimport("sppl.sym_util"))
    copy!(dnf, pyimport("sppl.dnf"))
    copy!(compiler, sppl_compiler.SPPL_Compiler)
    
    # ------------ Commands ------------ #

    copy!(Id, ast_compiler.Id)
    copy!(IdArray, ast_compiler.IdArray)
    copy!(Skip, ast_compiler.Skip)
    copy!(Sample, ast_compiler.Sample)
    copy!(Transform, ast_compiler.Transform)
    copy!(Cond, ast_compiler.Condition)
    copy!(IfElse, ast_compiler.IfElse)
    copy!(For, ast_compiler.For)
    copy!(Switch, ast_compiler.Switch)
    copy!(Sequence, ast_compiler.Sequence)

    # DNF.
    copy!(dnf_to_disjoint_union, dnf.dnf_to_disjoint_union)

    # Utils.
    copy!(binspace, sym_util.binspace)
    copy!(Fraction, fractions.Fraction)
    copy!(Sqrt, transforms.Sqrt)

end
__init__()

export fractions, sppl, dists, ast_compiler, sppl_compiler, transforms, sym_util, dnf, compiler
export Id, IdArray, Skip, Sample, Transform, Cond, IfElse, For, Switch, Sequence
const array = IdArray
export array
set(s) = py"{$s}"; export set
export dnf_to_disjoint_union
export binspace, Fraction, Sqrt

# Distributions.
include("distributions.jl")

# Model accessor utilities.
include("models.jl")
export condition, probability, mutual_information

include("dsl.jl")
export @sppl, @sppl_str

end # module
