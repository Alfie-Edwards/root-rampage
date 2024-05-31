Stack = {
    size = nil
}
setup_class(Stack)

function Stack:__init(...)
    super().__init(self)

    self.size = 0
    for _, item in ipairs({...}) do
        self:push(item)
    end
end

function Stack:push(x)
    self.size = self.size + 1
    self[self.size] = x
end

function Stack:pop()
    assert(self.size > 0, "Stack is empty.")
    local x = self[self.size]
    self[self.size] = nil
    self.size = self.size - 1
    return x
end

function Stack:head()
    return self[self.size]
end

function Stack:__pairs()
    return function(t, i)
        if i == nil then
            i = 1
        else
            i = i + 1
        end
        if i > self.size then
            return nil, nil
        end
        return i, self[i]
    end, self, nil
end

