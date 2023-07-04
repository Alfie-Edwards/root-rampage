require "utils"
require "rollback_model"
require "engine.rollback_engine"
require "states.game"
require "systems.game"
require "ui.simple_element"

Game = {
    MODE_PLAYER = {},
    MODE_ROOTS = {},
    MODE_ALL = {},

    t0 = nil,
    state = nil,
    mode = nil,
    rollback_model = nil,
    rollback_controller = nil,
    current_tick = nil,
    tick_offset = nil,
}
setup_class(Game, SimpleElement)

function Game.new(mode)
    local obj = magic_new()

    obj:set_properties(
        {
            width = canvas:width(),
            height = canvas:height(),
        }
    )

    obj.tick_offset = 0
    obj.mode = mode
    obj.state = GameState.new()
    obj.rollback_model = RollbackModel.new(obj.state)
    obj.rollback_engine = RollbackEngine.new(obj.rollback_model)
    obj.current_tick = -1
    obj.t0 = love.timer.getTime()

    return obj
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

function Game:receive_external_inputs(inputs, tick)
    self.rollback_engine:add_inputs(inputs, tick)
end

function Game:tick()
    self.current_tick = self.current_tick + 1
    self.rollback_engine:add_inputs(self:get_inputs(), self.current_tick)
    self.rollback_engine:tick()
end

function Game:update(dt)
    super().update(self, dt)

    self.tick_offset = self.tick_offset + dt
    while self.tick_offset / self.state.dt > 1 do
        self.tick_offset = self.tick_offset - self.state.dt
        self:tick()
    end
end

function Game:draw()
    super().draw(self)

    local dt = love.timer.getTime() - self.t0 - self.state.t

    GAME.draw(self.state, self:get_inputs(), dt)

    love.graphics.setColor({1, 1, 1, 0.05})
    love.graphics.setBlendMode("add")
    love.graphics.rectangle("fill", 0, 0, canvas:width(), canvas:height())
    love.graphics.setBlendMode("alpha")
end