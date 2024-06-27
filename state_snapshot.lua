require "snapshot"

StateSnapshot = {
    state = nil,
    handler = nil,
    changed = nil,
}
setup_class(StateSnapshot, Snapshot)
SnapshotFactory.register("PropertyTable", StateSnapshot)

-- A snapshot class specialised for State objects.
-- Avoid duplicating the whole state by only saving values which change.
function StateSnapshot:__init(state, shared_children)
    timer:push("StateSnapshot:__init("..state:type()..")")
    super().__init(self, shared_children)

    assert(state ~= nil)
    self.state = weak_ref(state)
    self.changed = {}
    self:subscribe()

    for _, v in pairs(state) do
        self:try_add_child_for(v)
    end
    timer:pop(10)
end

function StateSnapshot:subscribe()
    self:unsubscribe()
    self.handler = function(state, name, old_value, new_value)
        if self.saved_name_set[name] then
            -- Already saved an older value for this property.
            return
        end
        self:save(name, old_value)
        self.changed[name] = true
    end
    self.state.value.property_changed:subscribe(self.handler)
end

function StateSnapshot:unsubscribe()
    if self.handler == nil then
        return
    end
    self.state.value.property_changed:unsubscribe(self.handler)
    self.handler = nil
end

function StateSnapshot:reinit_impl()
    for name, _ in pairs(self.changed) do
        self:try_add_child_for(self.state.value[name])
    end
    self.changed = {}
end

function StateSnapshot:restore_impl()
    for name, _ in pairs(self.saved_name_set) do
        self.state.value[name] = self.saved[name]
    end
end

function StateSnapshot:cleanup_impl()
    self:unsubscribe()
end
