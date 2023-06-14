require "utils"

Event = {
    handlers = nil
}
setup_class("Event")

function Event.new()
    local obj = {}

    -- Intermediate instance with customised __call method to avoid passing this.
    local closure = {}
    setup_instance(closure, Event)

    closure.__call = function(...)
        for _, handler in ipairs(obj.handlers) do
            handler(...)
        end
    end

    obj.handlers = {}

    setup_instance(obj, closure)

    return obj
end

function Event:subscribe(handler)
    assert(handler ~= nil)
    table.insert(self.handlers, handler)
end

function Event:unsubscribe(handler)
    assert(handler ~= nil)
    remove_value(self.handlers, handler)
end

function Event:unsubscribe_all()
    self.handlers = {}
end

function Event.__call(...)

end
