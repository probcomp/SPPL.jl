# Accessor utility calls.
@inline mutual_information(model::PyObject, cond1::PyObject, cond2::PyObject) = model.mutual_information(cond1, cond2)
@inline condition(model::PyObject, cond::PyObject) = model.condition(cond)
@inline probability(model::PyObject, cond::PyObject) = model.prob(cond)
