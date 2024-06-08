Timer = {
    t0 = nil
}
setup_class(Timer)

function Timer:__init()
    super().__init(self)

    self:reset()
end

function Timer:reset()
    self.t0 = love.timer.getTime()
end

function Timer:report_and_reset(message)
    local t = love.timer.getTime()
    print(""..math.floor((t - self.t0) * 1000).."ms", message)
    self.t0 = t
end

function Timer:elapsed()
    return love.timer.getTime() - self.t0
end
