require "utils"
require "engine.state"
require "engine.snapshot"

StateSnapshot = {
    state = nil,
    handler = nil,
}
setup_class("StateSnapshot", Snapshot)
SnapshotFactory.register("State", StateSnapshot)

-- A snapshot class specialised for State objects.
-- Avoid duplicating the whole state by only saving values which change.
function StateSnapshot.new(state)
    local obj = Snapshot.new()
    setup_instance(obj, StateSnapshot)

    assert(state ~= nil)
    obj.state = state
    obj:subscribe()

    return obj
end

function StateSnapshot:subscribe()
    self:unsubscribe()
    self.handler = function(state, name, old_value, new_value)
        if self.saved_names_set[name] then
            -- Already saved an older value for this property.
            return
        end
        self:save(name, old_value)
    end
    self.state.property_changed:subscribe(self.handler)
end

function StateSnapshot:unsubscribe()
    if self.handler == nil then
        return
    end
    self.state.property_changed:unsubscribe(self.handler)
    self.handler = nil
end

function StateSnapshot:restore_impl()
    for name, _ in self.saved_name_set do
        self.state:set(name, self.saved[name])
    end
end

function StateSnapshot:cleanup_impl()
    self:unsubscribe()
end
