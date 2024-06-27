require "rollback_model"
require "rollback_engine"
require "states.game"
require "systems.game"
require "ui.layout_element"

Game = {
    MODE_PLAYER = {},
    MODE_ROOTS = {},
    MODE_ALL = {},
    INPUT_DELAY_S = 0.1,
    LATENCY_SYNC_THRESHOLD_S = 20,
}
setup_class(Game, LayoutElement)

function Game:__init(mode, host, connection)
    super().__init(self)

    self.width = canvas:width()
    self.height = canvas:height()

    self.tick_offset_s = 0
    self.mode = mode
    self.state = GameState()
    self.rollback_model = RollbackModel(self.state)
    self.rollback_engine = RollbackEngine(self.rollback_model)
    self.current_tick = -1
    self.t0 = t_now()
    self.input_delay = math.floor(Game.INPUT_DELAY_S / self.state.dt)
    self.t_last_tick = t_now()

    if self.input_delay > 0 then
        for t=0,self.input_delay-1,1 do
            self.rollback_engine:add_inputs(self.rollback_model:predict_inputs(), t)
        end
    end

    if mode == Game.MODE_ALL then
        assert(host == nil)
        assert(connection == nil)
    else
        assert(host ~= nil)
        assert(connection ~= nil)
        self.host = host
        self.connection = connection

        self.on_disconnected = function()
            self:unsubscribe()
            self.connection = nil
            self:quit(true)
        end
        if mode == Game.MODE_PLAYER then
            self.on_received = function(msg)
                if msg == "quit" then
                    self:quit(true)
                    return
                end
                local sep = msg:find("|")
                local tick = tonumber(msg:sub(1, sep-1))
                local inputs = Inputs.deserialize_roots(msg:sub(sep+1, -1))
                self.rollback_engine:add_inputs(inputs, tick)
            end
        elseif mode == Game.MODE_ROOTS then
            self.on_received = function(msg)
                if msg == "quit" then
                    self:quit(true)
                    return
                end
                local sep = msg:find("|")
                local tick = tonumber(msg:sub(1, sep-1))
                local inputs = Inputs.deserialize_player(msg:sub(sep+1, -1))
                self.rollback_engine:add_inputs(inputs, tick)
            end
        else
            error("unreachable")
        end
        connection.disconnected:subscribe(self.on_disconnected)
        connection.received:subscribe(self.on_received)
    end

end

function Game:get_inputs()
    local inputs = Inputs.new_undefined()

    local mouse_pos = canvas:screen_to_canvas(love.mouse.getX(), love.mouse.getY())

    if self.mode == Game.MODE_PLAYER then
        inputs.player_up = love.keyboard.isDown("up")
        inputs.player_down = love.keyboard.isDown("down")
        inputs.player_left = love.keyboard.isDown("left")
        inputs.player_right = love.keyboard.isDown("right")
        inputs.player_chop = love.keyboard.isDown("space")
    elseif self.mode == Game.MODE_ROOTS then
        inputs.roots_grow = love.mouse.isDown(1)
        inputs.roots_attack = love.mouse.isDown(2)
        inputs.roots_pos_x = mouse_pos.x
        inputs.roots_pos_y = mouse_pos.y
    elseif self.mode == Game.MODE_ALL then
        inputs.player_up = love.keyboard.isDown("up")
        inputs.player_down = love.keyboard.isDown("down")
        inputs.player_left = love.keyboard.isDown("left")
        inputs.player_right = love.keyboard.isDown("right")
        inputs.player_chop = love.keyboard.isDown("space")
        inputs.roots_grow = love.mouse.isDown(1)
        inputs.roots_attack = love.mouse.isDown(2)
        inputs.roots_pos_x = mouse_pos.x
        inputs.roots_pos_y = mouse_pos.y
    end

    return inputs
end

function Game:tick()
    timer:push("Game:tick")
    self.current_tick = self.current_tick + 1
    local input_tick = self.current_tick + self.input_delay
    local inputs = self:get_inputs()

    if self.connection ~= nil then
        if input_tick >= 0 then
            if self.mode == Game.MODE_PLAYER then
                self.connection:send(tostring(input_tick).."|"..inputs:serialize_player())
            elseif self.mode == Game.MODE_ROOTS then
                self.connection:send(tostring(input_tick).."|"..inputs:serialize_roots())
            else
                error("unreachable")
            end
        end

        if self.host ~= nil then
            timer:push("flush")
            self.host:flush()
            timer:pop(5)
        end
    end

    if input_tick >= 0 then
        self.rollback_engine:add_inputs(inputs, input_tick)
    end
    self.rollback_engine:tick()
    self.t_last_tick = t_now()
    timer:pop(self.state.dt * 1000)
end

function Game:unsubscribe()
    self.connection.disconnected:unsubscribe(self.on_disconnected)
    self.connection.received:unsubscribe(self.on_received)
end

function Game:quit(requested_by_peer)
    if self.host ~= nil then
        if self.connection ~= nil then
            self:unsubscribe()
            if not requested_by_peer then
                self.connection:send("quit")
            end
            view:set_content(LobbyMenu(self.host, self.connection))
            return
        elseif is_type(self.host, Server) then
            view:set_content(LobbyMenu(self.host))
            return
        else
            self.host:destroy()
        end
    end
    view:set_content(MainMenu())
end

function Game:update(dt)
    super().update(self, dt)

    if love.keyboard.isDown("escape") then
            self:quit(false)
        return
    end

    if self.host ~= nil then
        timer:push("poll")
        self.host:poll()
        timer:pop(5)
    end

    -- How much more we'd need to be ahead to incur a sync.

    local max_latency_lead_s = math.max(self.LATENCY_SYNC_THRESHOLD_S, (self.state.dt - self.INPUT_DELAY_S))
    local latency_sync_delta_s = max_latency_lead_s - (self.rollback_engine:delta() * self.state.dt)

    -- Limit ticks so we're at most self.LATENCY_SYNC_THRESHOLD_S ahead.
    self.tick_offset_s = math.min(self.tick_offset_s + dt, latency_sync_delta_s)

    if self.tick_offset_s >= self.state.dt then
        while self.tick_offset_s >= self.state.dt do
            self.tick_offset_s = self.tick_offset_s - self.state.dt
            self:tick()
        end
    else
        -- Just update rollback engine with the new inputs if we didn't tick at all.
        self.rollback_engine:refresh()
    end
end

function Game:draw()
    super().draw(self)

    local dt = t_now() - self.t_last_tick

    GAME.draw(self.state, self.rollback_engine:get_resolved_inputs(self.current_tick), dt)

    love.graphics.setColor({1, 1, 1, 0.05})
    love.graphics.setBlendMode("add")
    love.graphics.rectangle("fill", 0, 0, canvas:width(), canvas:height())
    love.graphics.setBlendMode("alpha")
end
