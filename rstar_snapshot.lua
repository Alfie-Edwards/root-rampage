require "snapshot"

RStarSnapshot = {
    rstar = nil,
    events = nil,
    add_handler = nil,
    remove_handler = nil,
    new = nil,
}
setup_class(RStarSnapshot, Snapshot)
SnapshotFactory.register("RStar", RStarSnapshot)

-- A snapshot class specialised for RStar trees.
-- Track additions / removals so we can undo them to roll back.
function RStarSnapshot:__init(rstar, shared_children)
    super().__init(self, shared_children)

    assert(rstar ~= nil)
    self.rstar = weak_ref(rstar)
    self.events = {}
    self.new = weak_table('k')
    self.dirty = false
    self:subscribe()
    for item, _ in pairs(rstar.item_map) do
        self:try_add_child_for(item)
    end
end

function RStarSnapshot:subscribe()
    self:unsubscribe()
    self.add_handler = function(item)
        table.insert(self.events, {"add", item})
        self.new[item] = true
        self.dirty = true
    end
    self.remove_handler = function(item)
        table.insert(self.events, {"remove", item})
        self.new[item] = nil
        self.dirty = true
    end
    self.rstar.value.added:subscribe(self.add_handler)
    self.rstar.value.removed:subscribe(self.remove_handler)
end

function RStarSnapshot:unsubscribe()
    if self.add_handler ~= nil then
        self.rstar.value.added:unsubscribe(self.add_handler)
        self.add_handler = nil
    end
    if self.remove_handler ~= nil then
        self.rstar.value.removed:unsubscribe(self.remove_handler)
        self.remove_handler = nil
    end
end

function RStarSnapshot:clear_saved()
    self.events = {}
    super().clear_saved(self)
end

function RStarSnapshot:restore_impl()
    if not self.dirty then
        return
    end
    for i=#self.events, 1, -1 do
        local event = self.events[i]
        if event[1] == "add" then
            self.rstar.value:remove(event[2].id)
        elseif event[1] == "remove" then
            self.rstar.value:add(event[2])
        else
            error("unrachable")
        end
    end
    self.events = {}
    self.new = weak_table('k')
    self.dirty = false
end

function RStarSnapshot:reinit_impl()
    if not self.dirty then
        return
    end
    for item, _ in pairs(self.new) do
        self:try_add_child_for(item)
    end
    self.new = weak_table('k')
    self.dirty = false
end

function RStarSnapshot:cleanup_impl()
    self:unsubscribe()
end
