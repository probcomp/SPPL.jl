module SPPL

using MacroTools
using MacroTools: @capture, rmlines, unblock
using PythonCall

# Holds a reference to the objects in
# the initialized Python runtime.
struct PythonObject
    ref::Ref{PythonCall.Py}
    PythonObject() = new(Ref{PythonCall.Py}())
end

@doc(
"""
    struct PythonObject
        ref::Ref{Any}
    end
A safe (pre-allocated) pointer for use with exporting
loaded Python modules.
The functionality should match `PyNULL` from `PyCall`.
""", PythonObject)

function (po::PythonObject)(args...; kwargs...)
    ref = getfield(po, :ref)
    return ref[](args...; pairs(kwargs)...)
end

import Base: getproperty, display

function getproperty(po::PythonObject, s::Symbol)
    ref = getfield(po, :ref)
    return getproperty(ref[], s)
end

function set!(po::PythonObject, a)
    ref = getfield(po, :ref)
    ref[] = a
    return nothing
end

function display(po::PythonObject)
    ref = getfield(po, :ref)
    display(ref[])
end

# ------------ Precompile compatibility ------------ #

const fractions = PythonObject()
const sppl = PythonObject()
const dists = PythonObject()
const ast_compiler = PythonObject()
const sppl_compiler = PythonObject()
const transforms = PythonObject()
const sym_util = PythonObject()
const dnf = PythonObject()
const compiler = PythonObject()
const Id = PythonObject()
const IdArray = PythonObject()
const Skip = PythonObject()
const Sample = PythonObject()
const Transform = PythonObject()
const Cond = PythonObject()
const IfElse = PythonObject()
const For = PythonObject()
const Switch = PythonObject()
const Sequence = PythonObject()
const dnf_to_disjoint_union = PythonObject()
const binspace = PythonObject()
const Fraction = PythonObject()
const Sqrt = PythonObject()

function load_python_deps!()

    # ------------ Imports ------------ #

    set!(fractions, pyimport("fractions"))
    set!(sppl, pyimport("sppl"))
    set!(dists, pyimport("sppl.distributions"))
    set!(ast_compiler, pyimport("sppl.compilers.ast_to_spn"))
    set!(sppl_compiler, pyimport("sppl.compilers.sppl_to_python"))
    set!(transforms, pyimport("sppl.transforms"))
    set!(sym_util, pyimport("sppl.sym_util"))
    set!(dnf, pyimport("sppl.dnf"))
    set!(compiler, sppl_compiler.SPPL_Compiler)
    
    # ------------ Commands ------------ #

    set!(Id, ast_compiler.Id)
    set!(IdArray, ast_compiler.IdArray)
    set!(Skip, ast_compiler.Skip)
    set!(Sample, ast_compiler.Sample)
    set!(Transform, ast_compiler.Transform)
    set!(Cond, ast_compiler.Condition)
    set!(IfElse, ast_compiler.IfElse)
    set!(For, ast_compiler.For)
    set!(Switch, ast_compiler.Switch)
    set!(Sequence, ast_compiler.Sequence)

    # DNF.
    set!(dnf_to_disjoint_union, dnf.dnf_to_disjoint_union)

    # Utils.
    set!(binspace, sym_util.binspace)
    set!(Fraction, fractions.Fraction)
    set!(Sqrt, transforms.Sqrt)

end
__init__() = load_python_deps!()

export fractions, sppl, dists, ast_compiler, sppl_compiler, transforms, sym_util, dnf, compiler
export Id, IdArray, Skip, Sample, Transform, Cond, IfElse, For, Switch, Sequence
const array = IdArray
export array
set(s) = Py(s); export set
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
