require "utils"
require "inputs"
require "engine.rollback_model_interface"
require "engine.snapshot"

RollbackModel = {
    state = nil
}
setup_class(RollbackModel, RollbackModelInterface)

function RollbackModel.new(state)
    local obj = magic_new()

    assert(state ~= nil)
    obj.state = state

    return obj
end

function RollbackModel:tick(inputs)
    GAME.update(self.state, inputs)
end

function RollbackModel:take_snapshot()
    return SnapshotFactory.build(self.state)
end

function RollbackModel:merge_inputs(a, b)
    local result = Inputs.new_undefined()

    for k, _ in pairs(result.properties_set) do
        if a ~= nil and a[k] ~= INPUT_UNDEFINED then
            result[k] = a[k]
        elseif b ~= nil and b[k] ~= INPUT_UNDEFINED then
            result[k] = b[k]
        end
    end

    return result
end

function RollbackModel:predict_inputs(partial_inputs, prev_inputs)
    local prediction = Inputs.new_defaults()

    for k, _ in pairs(prediction.properties_set) do
        if partial_inputs ~= nil and  partial_inputs[k] ~= INPUT_UNDEFINED then
            prediction[k] = partial_inputs[k]
        elseif prev_inputs ~= nil and prev_inputs[k] ~= INPUT_UNDEFINED then
            prediction[k] = prev_inputs[k]
        end
    end

    return prediction
end

function RollbackModel:are_inputs_complete(inputs)
    for k, _ in pairs(inputs.properties_set) do
        if inputs[k] == INPUT_UNDEFINED then
            return false
        end
    end
    return true
end

function RollbackModel:rollback(snapshot)
    assert(snapshot.state == self.state)
    snapshot:restore()
end
