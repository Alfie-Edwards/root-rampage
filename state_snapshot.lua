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
    super().__init(self, shared_children)

    assert(state ~= nil)
    self.any_changed = false
    self.state = weak_ref(state)
    self.changed = weak_table('k')
    self:subscribe()

    for _, v in pairs(state) do
        self:try_add_child_for(v)
    end
end

function StateSnapshot:subscribe()
    self:unsubscribe()
    self.handler = function(state, name, old_value, new_value)
        if self.saved_name_set[name] then
            -- Already saved an older value for this property.
            return
        end
        self.any_changed = true
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
    if self.any_changed then
        for name, _ in pairs(self.changed) do
            any = true
            self:try_add_child_for(self.state.value[name])
        end
        self.changed = weak_table('k')
        self.any_changed = false
    end
end

function StateSnapshot:restore_impl()
    if self.any_changed then
        for name, _ in pairs(self.saved_name_set) do
            self.state.value[name] = self.saved[name]
        end
        self.changed = weak_table('k')
        self.saved = {}
        self.saved_name_set = {}
        self.any_saved = false
        self.any_changed = false
    end
end

function StateSnapshot:cleanup_impl()
    self:unsubscribe()
end
