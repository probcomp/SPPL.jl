# Accessor utility calls.
@inline mutual_information(model::Py, cond1::Py, cond2::Py) = model.mutual_information(cond1, cond2)
@inline condition(model::Py, cond::Py) = model.condition(cond)
@inline probability(model::Py, cond::Py) = model.prob(cond)
