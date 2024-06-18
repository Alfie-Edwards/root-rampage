require "rollback_model"
require "rollback_engine"
require "states.game"
require "systems.game"
require "ui.layout_element"

Game = {
    MODE_PLAYER = {},
    MODE_ROOTS = {},
    MODE_ALL = {},
    INPUT_DELAY_S = 0,
    LATENCY_WAIT_THRESHOLD_S = 1,

    t0 = nil,
    state = nil,
    mode = nil,
    rollback_model = nil,
    rollback_controller = nil,
    current_tick = nil,
    tick_offset = nil,
    input_delay = nil,
    max_latency = nil,
}
setup_class(Game, LayoutElement)

function Game:__init(mode, host, connection)
    super().__init(self)

    self.width = canvas:width()
    self.height = canvas:height()

    self.tick_offset = 10
    self.mode = mode
    self.state = GameState()
    self.rollback_model = RollbackModel(self.state)
    self.rollback_engine = RollbackEngine(self.rollback_model)
    self.current_tick = -1
    self.t0 = love.timer.getTime()
    self.input_delay = math.floor(Game.INPUT_DELAY_S / self.state.dt)
    self.latency_wait_threshold = math.floor(Game.LATENCY_WAIT_THRESHOLD_S / self.state.dt)

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
        connection.disconnected:subscribe(
            function()
                self:quit()
            end
        )
        if mode == Game.MODE_PLAYER then
            connection.received:subscribe(
                function(msg)
                    local sep = msg:find("|")
                    local tick = tonumber(msg:sub(1, sep-1))
                    local inputs = Inputs.deserialize_roots(msg:sub(sep+1, -1))
                    self.rollback_engine:add_inputs(inputs, tick)
                end
            )
        elseif mode == Game.MODE_ROOTS then
            connection.received:subscribe(
                function(msg)
                    local sep = msg:find("|")
                    local tick = tonumber(msg:sub(1, sep-1))
                    local inputs = Inputs.deserialize_player(msg:sub(sep+1, -1))
                    self.rollback_engine:add_inputs(inputs, tick)
                end
            )
        else
            error("unreachable")
        end
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
            self.host:poll(1)
        end
    end

    if input_tick >= 0 then
        self.rollback_engine:add_inputs(inputs, input_tick)
    end
    self.rollback_engine:tick()
end

function Game:quit()
    if self.host ~= nil then
        self.connection:request_disconnect()
        self.host:destroy()
    end
    view:set_content(MainMenu())
end

function Game:update(dt)
    super().update(self, dt)

    if love.keyboard.isDown("escape") then
        self:quit()
        return
    end

    if self.rollback_engine:delta() <= self.latency_wait_threshold then
        self.tick_offset = math.min(self.tick_offset + dt, Game.LATENCY_WAIT_THRESHOLD_S)
        while self.tick_offset / self.state.dt > 1 do
            self.tick_offset = self.tick_offset - self.state.dt
            self:tick()
            self.tick_offset = 0 -- debug disable catchup
        end
    end
end

function Game:draw()
    super().draw(self)

    local dt = 0

    GAME.draw(self.state, self:get_inputs(), dt)

    love.graphics.setColor({1, 1, 1, 0.05})
    love.graphics.setBlendMode("add")
    love.graphics.rectangle("fill", 0, 0, canvas:width(), canvas:height())
    love.graphics.setBlendMode("alpha")
end
