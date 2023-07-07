
RollbackModelInterface = {
}
setup_class(RollbackModelInterface)

function RollbackModelInterface.new()
    local obj = magic_new()

    return obj
end

function RollbackModelInterface:tick(inputs)
    error("Rollback models must implement the `tick(inputs)` method.")
end

function RollbackModelInterface:take_snapshot()
    error("Rollback models must implement the `take_snapshot()` method.")
end

function RollbackModelInterface:merge_inputs(a, b)
    error("Rollback models must implement the `merge_inputs(a, b)` method.")
end

function RollbackModelInterface:predict_inputs(partial_inputs, prev_inputs)
    error("Rollback models must implement the `predict_inputs(partial_inputs, prev_inputs)` method.")
end

function RollbackModelInterface:are_inputs_complete(inputs)
    error("Rollback models must implement the `are_inputs_complete(inputs)` method.")
end

function RollbackModelInterface:rollback(snapshot)
    error("Rollback models must implement the `rollback(snapshot)` method.")
end