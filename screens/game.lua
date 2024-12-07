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
    LATENCY_AVG = 90,
    LATENCY_SYNC_THRESHOLD_S = 0,
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
    self.t_last_update = t_now()
    self.t_last_tick = self.t_last_update
    self.opponent_latency_buffer_s = RingBuffer(Game.LATENCY_AVG)
    self.latency_buffer_s = RingBuffer(Game.LATENCY_AVG)
    self.mean_latency_s = 0
    self.mean_opponent_latency_s = 0
    self.manual_step = false

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
                local tokens = split(msg, "|", 3)
                local tick = tonumber(tokens[1])
                self:_push_opponent_latency(tonumber(tokens[2]))
                local inputs = Inputs.deserialize_roots(tokens[3])
                self.rollback_engine:add_inputs(inputs, tick)
            end
        elseif mode == Game.MODE_ROOTS then
            self.on_received = function(msg)
                if msg == "quit" then
                    self:quit(true)
                    return
                end
                local tokens = split(msg, "|", 3)
                local tick = tonumber(tokens[1])
                self:_push_opponent_latency(tonumber(tokens[2]))
                local inputs = Inputs.deserialize_player(tokens[3])
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
        inputs.player_up = love.keyboard.isDown("up") or love.keyboard.isDown("w")
        inputs.player_down = love.keyboard.isDown("down") or love.keyboard.isDown("s")
        inputs.player_left = love.keyboard.isDown("left") or love.keyboard.isDown("a")
        inputs.player_right = love.keyboard.isDown("right") or love.keyboard.isDown("d")
        inputs.player_chop = love.keyboard.isDown("space")
        inputs.player_dash = love.keyboard.isDown("lshift")
    elseif self.mode == Game.MODE_ROOTS then
        inputs.roots_grow = love.mouse.isDown(1)
        inputs.roots_attack = love.mouse.isDown(2)
        inputs.roots_pos_x = mouse_pos.x
        inputs.roots_pos_y = mouse_pos.y
    elseif self.mode == Game.MODE_ALL then
        inputs.player_up = love.keyboard.isDown("up") or love.keyboard.isDown("w")
        inputs.player_down = love.keyboard.isDown("down") or love.keyboard.isDown("s")
        inputs.player_left = love.keyboard.isDown("left") or love.keyboard.isDown("a")
        inputs.player_right = love.keyboard.isDown("right") or love.keyboard.isDown("d")
        inputs.player_chop = love.keyboard.isDown("space")
        inputs.player_dash = love.keyboard.isDown("lshift")
        inputs.roots_grow = love.mouse.isDown(1)
        inputs.roots_attack = love.mouse.isDown(2)
        inputs.roots_pos_x = mouse_pos.x
        inputs.roots_pos_y = mouse_pos.y
    end

    return inputs
end

function Game:tick()
    self.current_tick = self.current_tick + 1
    local input_tick = self.current_tick + self.input_delay
    local inputs = self:get_inputs()

    if self.connection ~= nil then
        if input_tick >= 0 then
            if self.mode == Game.MODE_PLAYER then
                self.connection:send(tostring(input_tick).."|"..self.latency_buffer_s:head().."|"..inputs:serialize_player())
            elseif self.mode == Game.MODE_ROOTS then
                self.connection:send(tostring(input_tick).."|"..self.latency_buffer_s:head().."|"..inputs:serialize_roots())
            else
                error("unreachable")
            end
        end

        if self.host ~= nil then
            self.host:flush()
        end
    end

    if input_tick >= 0 then
        self.rollback_engine:add_inputs(inputs, input_tick)
    end
    self.rollback_engine:tick()
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

function Game:keypressed(key, scancode, isrepeat)
    if key == "]" then
        if self.manual_step then
            self:tick()
        else
            self.manual_step = true
        end
    elseif key == "[" then
        self.manual_step = false
        self.t_last_update = t_now()
        self.t_last_tick = t_now()
    elseif key == "end" then
        if not DO_PROFILE then
            return
        end
        local names = {}
        for name, _ in pairs(_profile) do
            table.insert(names, name)
        end
        table.sort(names, function(a, b) return _profile[a] > _profile[b] end)
        for _, name in ipairs(names) do
            print(_profile[name].." "..name)
        end
    end
end

function Game:update(dt)
    super().update(self, dt)

    if love.keyboard.isDown("escape") then
            self:quit(false)
        return
    end

    if self.manual_step then
        return
    end

    if self.host ~= nil then
        self.host:poll()
    end

    local latency = math.max(0, self.rollback_engine:delta() * self.state.dt)
    self:_push_latency(latency)
    local latency_diff_s = self.mean_latency_s - self.mean_opponent_latency_s


    local now = t_now()
    self.tick_offset_s = self.tick_offset_s + now - self.t_last_update
    self.t_last_update = now

    if math.abs(latency_diff_s) > Game.LATENCY_SYNC_THRESHOLD_S then
        self.tick_offset_s = self.tick_offset_s - (latency_diff_s * 0.35 / Game.LATENCY_AVG)
    end
    self.tick_offset_s = math.min(self.tick_offset_s, self.state.dt * 3)

    if self.tick_offset_s >= self.state.dt then
        while self.tick_offset_s >= self.state.dt do
            self.tick_offset_s = self.tick_offset_s - self.state.dt
            self:tick()
        end
        self.t_last_tick = now
    else
        -- Just update rollback engine with the new inputs if we didn't tick at all.
        self.rollback_engine:refresh()
    end
end

function Game:_push_latency(l)
    if self.latency_buffer_s.length == 0 then
        self.mean_latency_s = l
    elseif self.latency_buffer_s.length < 300 then
        self.mean_latency_s = ((self.mean_latency_s * self.latency_buffer_s.length) + l) / (self.latency_buffer_s.length + 1)
    else
        self.mean_latency_s = (self.mean_latency_s + (l - self.latency_buffer_s:tail()) / 300)
    end
    self.latency_buffer_s:append(l)
end

function Game:_push_opponent_latency(l)
    if self.opponent_latency_buffer_s.length == 0 then
        self.mean_opponent_latency_s = l
    elseif self.opponent_latency_buffer_s.length < 300 then
        self.mean_opponent_latency_s = ((self.mean_opponent_latency_s * self.opponent_latency_buffer_s.length) + l) / (self.opponent_latency_buffer_s.length + 1)
    else
        self.mean_opponent_latency_s = (self.mean_opponent_latency_s + (l - self.opponent_latency_buffer_s:tail()) / 300)
    end
    self.opponent_latency_buffer_s:append(l)
end


function Game:draw()
    super().draw(self)

    local dt = t_now() - self.t_last_tick
    if self.manual_step then
        dt = 0
    end

    local inputs = self.rollback_model:merge_inputs(self:get_inputs(), self.rollback_engine:get_resolved_inputs(self.current_tick))
    GAME.draw(self.state, inputs, dt)
end
