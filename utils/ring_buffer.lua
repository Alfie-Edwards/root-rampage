RingBuffer = {
    length = nil,
    tail = nil,
    capacity = nil,
}
setup_class(RingBuffer)

function RingBuffer:__init(capacity)
    super().__init(self)

    self.length = 0
    self.i_head = 1
    self.capacity = capacity
end

function RingBuffer:append(x)
    self.i_head = (self.i_head % self.capacity) + 1 
    if self.length < self.capacity then
        self.length = self.length + 1
    end
    self[self.i_head] = x
end

function RingBuffer:head()
    assert(self.length > 0)
    return self[self.i_head]
end

function RingBuffer:tail()
    assert(self.length > 0)
    return self[((self.i_head - self.length + self.capacity) % self.capacity) + 1]
end

function RingBuffer:pop_head()
    assert(self.length > 0)
    self.length = self.length - 1
    self.i_head = ((self.i_head + self.capacity - 2) % self.capacity) + 1
end

function RingBuffer:pop_tail()
    assert(self.length > 0)
    self.length = self.length - 1
end

function RingBuffer:__pairs()
    local i = 0
    return function(t, k)
        i = i + 1
        if i > self.length then
            return nil
        end
        return i, self[((self.i_head - self.length + i + self.capacity - 1) % self.capacity) + 1]
    end
end
