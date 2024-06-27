require "snapshot"
SAVED_NIL = {}

TableSnapshot = {
    t = nil,
}
setup_class(TableSnapshot, Snapshot)
SnapshotFactory.register("table", TableSnapshot)

-- A snapshot class for any table.
-- Generic but copies the whole state.
function TableSnapshot:__init(t, shared_children)
    timer:push("TableSnapshot:__init")
    super().__init(self, shared_children)

    assert(t ~= nil)
    self.t = weak_ref(t)
    for name, value in pairs(t) do
        self:save(name, value)
    end
    timer:pop(10)
end

function TableSnapshot:restore_impl()
    for name, _ in pairs(self.saved_name_set) do
        local value = self.saved[name]
        if self.t.value[name] ~= value then
            self.t.value[name] = value
        end
    end
    for name, _ in pairs(self.t.value) do
        if self.saved_name_set[name] ~= true then
            self.t.value[name] = nil
        end
    end
end

function TableSnapshot:reinit_impl()
    for name, value in pairs(self.t.value) do
        self:save(name, value)
    end
end

function TableSnapshot:cleanup_impl()
end
