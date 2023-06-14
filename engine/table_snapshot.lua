require "utils"
require "engine.state"
require "engine.snapshot"

TableSnapshot = {
    t = nil,
}
setup_class("TableSnapshot", Snapshot)
SnapshotFactory.register("table", TableSnapshot)

-- A snapshot class for any table.
-- Generic but copies the whole state.
function TableSnapshot.new(t)
    local obj = Snapshot.new()
    setup_instance(obj, TableSnapshot)

    assert(t ~= nil)
    obj.t = t
    for name, value in pairs(t) do
        obj:save(name, value)
    end

    return obj
end

function TableSnapshot:restore_impl()
    for name, _ in self.saved_name_set do
        local value = self.saved[name]
        if self.t[name] ~= value then
            self.t[name] = value
        end
    end
    for name, _ in self.t do
        if self.saved_name_set[name] ~= true then
            self.t[name] = nil
        end
    end
end

function TableSnapshot:cleanup_impl()
    self:unsubscribe()
end
