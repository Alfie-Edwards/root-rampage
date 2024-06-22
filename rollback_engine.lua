
RollbackEngine = {
    target_tick = nil,
    current_tick = nil,
    snapshot_tick = nil,
    input_record = nil,
    prediction_record = nil,
    snapshot = nil,
    model = nil,
    dirty = nil,
}
setup_class(RollbackEngine)

function RollbackEngine:__init(model)
    super().__init(self)

    self.target_tick = -1
    self.current_tick = -1
    self.snapshot_tick = -1
    self.frontier_tick = -1
    self.input_record = {}
    self.prediction_record = {}
    self.snapshot = model:take_snapshot()
    self.dirty = false

    self.model = model
end

function RollbackEngine:delta()
    return self.target_tick - self.frontier_tick
end

function RollbackEngine:tick()
    timer:push("RollbackEngine:tick")
    self.target_tick = self.target_tick + 1
    if self.input_record[self.target_tick] ~= nil then
        self.dirty = true
    end
    self:refresh()
    timer:pop(self.model.state.dt * 1000)
end

function RollbackEngine:refresh()
    -- Update snapshot/state based on any new inputs.
    if (self.target_tick > self.snapshot_tick) and (self.frontier_tick > self.snapshot_tick) then
        self:_update_snapshot()
    elseif self.dirty then
        self:_rollback_to_snapshot()
    end
    if self.current_tick ~= self.target_tick then
        self:_play_to_target()
    end
end

function RollbackEngine:add_inputs(inputs, tick)
    assert(tick > self.snapshot_tick)
    assert(self.input_record[tick] == nil or self.prediction_record[tick] ~= nil)

    -- Merge with any existing inputs for this tick.
    if self.input_record[tick] ~= nil then
        inputs = self.model:merge_inputs(self.input_record[tick], inputs)
    end

    self.input_record[tick] = inputs

    -- Record the inputs.
    if self.model:are_inputs_complete(inputs) then
        self.prediction_record[tick]  = nil
        if tick == (self.frontier_tick + 1) then
            self.frontier_tick = tick
        end
    else
        local prev_inputs = self:get_resolved_inputs(tick - 1)
        local prediction = self.model:predict_inputs(inputs, prev_inputs)
        self.prediction_record[tick] = prediction
    end

    if tick <= self.target_tick then
        self.dirty = true
    end

    -- Recalculate dependent predictions.
    local t = tick
    while self.prediction_record[t + 1] ~= nil do
        self.prediction_record[t + 1] = self.model:predict_inputs(self.input_record[t + 1], self:get_resolved_inputs(t))
        t = t + 1
    end
end

function RollbackEngine:get_resolved_inputs(tick)
    return self.prediction_record[tick] or self.input_record[tick] or self.model:predict_inputs()
end

function RollbackEngine:_update_snapshot()
    timer:push("RollbackEngine:_update_snapshot")

    -- Calculate potentialially new snapshot tick.
    local new_snapshot_tick = self.snapshot_tick
    while new_snapshot_tick < self.target_tick and
            self.input_record[new_snapshot_tick + 1] ~= nil and
            self.prediction_record[new_snapshot_tick + 1] == nil do
        new_snapshot_tick = new_snapshot_tick + 1
    end

    if new_snapshot_tick == self.snapshot_tick then
        timer:pop(self.model.state.dt * 1000)
        return
    end

    -- Reset to old snapshot tick and play to new snapshot tick.
    self:_rollback_to_snapshot()

    timer:push("RollbackEngine:tick_model("..(new_snapshot_tick - self.current_tick..")"))
    while self.current_tick < new_snapshot_tick do
        self.input_record[self.current_tick] = nil
        self.current_tick = self.current_tick + 1
        self.model:tick(self.input_record[self.current_tick])

        -- Clear records up to the new snapshot tick.
        -- Don't clean up current inputs as they're used for rendering.
    end
    timer:pop(self.model.state.dt * 1000)

    timer:push("RollbackEngine:take_snapshot")
    -- Create the new snapshot.
    if self.snapshot == nil then
        self.snapshot = self.model:take_snapshot()
    else
        self.snapshot:reinit()
    end
    self.snapshot_tick = new_snapshot_tick
    timer:pop(self.model.state.dt * 1000)
    timer:pop(self.model.state.dt * 1000)
end

function RollbackEngine:_rollback_to_snapshot()
    timer:push("RollbackEngine:_rollback_to_snapshot")
    if self.current_tick ~= self.snapshot_tick then
        self.model:rollback(self.snapshot)
        self.current_tick = self.snapshot_tick
    end
    self.dirty = false
    timer:pop(self.model.state.dt * 1000)
end

function RollbackEngine:_play_to_target()
    timer:push("RollbackEngine:_play_to_target")
    -- Play until target tick.
    while self.current_tick < self.target_tick do
        local next_tick = self.current_tick + 1

        -- Fill in predictions as we go if they haven't been done yet.
        if self.prediction_record[next_tick] == nil and not self.model:are_inputs_complete(self.input_record[next_tick]) then
            self.prediction_record[next_tick] = self.model:predict_inputs(self.input_record[next_tick], self:get_resolved_inputs(self.current_tick))
        end

        self.model:tick(self:get_resolved_inputs(next_tick))
        self.current_tick = next_tick
    end
    timer:pop(self.model.state.dt * 1000)
end
