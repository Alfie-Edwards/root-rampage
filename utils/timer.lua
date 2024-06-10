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

function Timer:report_and_reset(message, threshold)
    local t = love.timer.getTime()
    local ms = math.floor((t - self.t0) * 1000)
    if ms > nil_coalesce(threshold, -1) then
        print(""..ms.."ms", message)
    end
    self.t0 = t
end

function Timer:elapsed()
    return love.timer.getTime() - self.t0
end
