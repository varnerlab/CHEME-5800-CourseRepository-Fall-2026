module Week16Core

export bridge_map, course_method_map, validate_computational_contract

"""The common Fall method families and the engineering question each answers."""
function course_method_map()
    return [
        (weeks = "1–3", family = "programming and data contracts", question = "How is the problem represented and tested?"),
        (weeks = "4–6", family = "graphs and optimization", question = "What feasible structure or decision is best?"),
        (weeks = "6–8", family = "numerical linear algebra and regression", question = "What low-dimensional model explains the observations?"),
        (weeks = "9", family = "classification and nonlinear optimization", question = "Which discrete outcome is supported by the features?"),
        (weeks = "10", family = "online learning and bandits", question = "How should decisions adapt as feedback arrives?"),
        (weeks = "11–12", family = "Markov decisions and Q-learning", question = "How should actions account for delayed consequences?"),
        (weeks = "13–14", family = "interfaces, provenance, and trust", question = "How can a computation cross a system boundary safely?"),
        (weeks = "15", family = "numerical dynamics", question = "How does a continuous model become a stable state update?"),
    ]
end

"""Explicit prerequisite handoff from Fall 5800 to Spring 5820."""
function bridge_map()
    return [
        (fall = "SVD, regression, and classification", spring = "kernels and neural feature learning"),
        (fall = "optimization and tested numerical programs", spring = "training algorithms and backpropagation"),
        (fall = "Markov decisions and tabular Q-learning", spring = "deep reinforcement learning"),
        (fall = "time discretization and state updates", spring = "state-space, recurrent, and spiking models"),
        (fall = "typed interfaces and trust boundaries", spring = "reproducible learned-system integration"),
    ]
end

"""Report missing fields in a complete computational claim."""
function validate_computational_contract(contract::NamedTuple)
    required = (:question, :representation, :method, :evidence, :limitations)
    missing = String[]
    for field in required
        if !haskey(contract, field) || isempty(strip(string(get(contract, field, ""))))
            push!(missing, string(field))
        end
    end
    return (complete = isempty(missing), missing = missing)
end

end
