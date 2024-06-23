Timer = {
    scope = nil
}
setup_class(Timer)

function Timer:__init()
    super().__init(self)

    self.scope = Stack()
end

function Timer:reset()
end

function Timer:push(name)
    self.scope:push({name, t_now()})
end

function Timer:pop(print_threshold)
    assert(self.scope.size)

    local t = t_now()
    local name, t0 = unpack(self.scope:pop())
    local ms = math.floor((t - t0) * 1000)
    if ms >= nil_coalesce(print_threshold, 0) then
        print(""..ms.."ms", name)
    end
end

function Timer:poppush(print_threshold, name)
    self:pop(print_threshold)
    self:push(name)
end

timer = Timer()
