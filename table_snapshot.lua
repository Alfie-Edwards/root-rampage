require "snapshot"

TableSnapshot = {
    t = nil,
}
setup_class(TableSnapshot, Snapshot)
SnapshotFactory.register("table", TableSnapshot)

-- A snapshot class for any table.
-- Generic but copies the whole state.
function TableSnapshot:__init(t, shared_children)
    super().__init(self, shared_children)

    assert(t ~= nil)
    self.t = t
    for name, value in pairs(t) do
        self:save(name, value)
    end
end

function TableSnapshot:restore_impl()
    for name, _ in pairs(self.saved_name_set) do
        local value = self.saved[name]
        if self.t[name] ~= value then
            self.t[name] = value
        end
    end
    for name, _ in pairs(self.t) do
        if self.saved_name_set[name] ~= true then
            self.t[name] = nil
        end
    end
end

function TableSnapshot:cleanup_impl()
end
