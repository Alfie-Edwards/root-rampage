require "utils"

RollbackEngine = {
    target_tick = nil,
    current_tick = nil,
    snapshot_tick = nil,
    input_record = nil,
    prediction_record = nil,
    snapshot = nil,
    model = nil,
}
setup_class(RollbackEngine)

function RollbackEngine.new(model)
    local obj = magic_new()

    obj.target_tick = -1
    obj.current_tick = -1
    obj.snapshot_tick = -1
    obj.input_record = {}
    obj.prediction_record = {}
    obj.snapshot = model:take_snapshot() 

    obj.model = model

    return obj
end

function RollbackEngine:tick()
    self.target_tick = self.target_tick + 1
    self:_update_snapshot()
    self:_play_to_target()
end

function RollbackEngine:add_inputs(inputs, tick)
    assert(tick > self.snapshot_tick)
    assert(self.input_record[tick] == nil or self.prediction_record[tick] ~= nil)

    -- Merge with any existing inputs for this tick.
    if self.input_record[tick] ~= nil then
        inputs = self.model:merge_inputs(self.input_record[tick], inputs)
    end

    self.input_record[tick] = inputs

    -- Prepare to replay unless inputs are in the future.
    if tick <= self.target_tick then
        self:_rollback_to_snapshot()
    end

    -- Record the inputs.
    if self.model:are_inputs_complete(inputs) then
        self.prediction_record[tick]  = nil
    else
        local prev_inputs = self.prediction_record[tick - 1] or self.input_record[tick - 1]
        local prediction = self.model:predict_inputs(inputs, prev_inputs)
        self.prediction_record[tick] = prediction
    end

    -- Recalculate dependent predictions.
    local t = tick
    while self.prediction_record[t + 1] ~= nil do
        self.prediction_record[t + 1] = self.model:predict_inputs(self.input_record[t + 1], self.prediction_record[t] or self.input_record[t])
        t = t + 1
    end

    -- Replay unless inputs are in the future.
    if tick <= self.target_tick then
        self:_update_snapshot()
        self:_play_to_target()
    end
end

function RollbackEngine:get_inputs_from_tick(tick)
    return self.input_record[tick]
end

function RollbackEngine:_update_snapshot()

    -- Calculate potentialially new snapshot tick.
    local new_snapshot_tick = self.snapshot_tick
    while new_snapshot_tick < self.target_tick and
            self.input_record[new_snapshot_tick + 1] ~= nil and
            self.prediction_record[new_snapshot_tick + 1] == nil do
        new_snapshot_tick = new_snapshot_tick + 1
    end

    if new_snapshot_tick == self.snapshot_tick then
        return
    end

    -- Reset to old snapshot tick and play to new snapshot tick.
    self:_rollback_to_snapshot()

    while self.current_tick < new_snapshot_tick do
        self.current_tick = self.current_tick + 1
        self.model:tick(self.input_record[self.current_tick])

        -- Clear records up to the new snapshot tick.
        self.input_record[self.current_tick] = nil
    end

    -- Create the new snapshot.
    if self.snapshot ~= nil then
        self.snapshot:cleanup()
    end
    self.snapshot = self.model:take_snapshot()
    self.snapshot_tick = new_snapshot_tick

    -- Play to target.
    self:_play_to_target()
end

function RollbackEngine:_rollback_to_snapshot()
    if self.current_tick ~= self.snapshot_tick then
        self.model:rollback(self.snapshot)
        self.current_tick = self.snapshot_tick
    end
end

function RollbackEngine:_play_to_target()
        -- Play until target tick.
    for t = (self.current_tick + 1), self.target_tick, 1 do
        assert(self.input_record[t] ~= nil)
        self.model:tick(self.prediction_record[t] or self.input_record[t])
    end
end
