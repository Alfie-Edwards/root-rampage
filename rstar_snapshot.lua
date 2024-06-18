require "snapshot"

RStarSnapshot = {
    rstar = nil,
    events = nil,
    add_handler = nil,
    remove_handler = nil,
}
setup_class(RStarSnapshot, Snapshot)
SnapshotFactory.register("RStar", RStarSnapshot)

-- A snapshot class specialised for RStar trees.
-- Track additions / removals so we can undo them to roll back.
function RStarSnapshot:__init(rstar, shared_children)
    super().__init(self, shared_children)

    assert(rstar ~= nil)
    self.rstar = rstar
    self.events = {}
    self:subscribe()
end

function RStarSnapshot:subscribe()
    self:unsubscribe()
    self.add_handler = function(item, x, y)
        table.insert(self.events, {"add", item, x, y})
    end
    self.remove_handler = function(item, x, y)
        table.insert(self.events, {"remove", item, x, y})
    end
    self.rstar.added:subscribe(self.add_handler)
    self.rstar.removed:subscribe(self.remove_handler)
end

function RStarSnapshot:unsubscribe()
    if self.add_handler ~= nil then
        self.rstar.added:unsubscribe(self.add_handler)
        self.add_handler = nil
    end
    if self.remove_handler ~= nil then
        self.rstar.removed:unsubscribe(self.remove_handler)
        self.remove_handler = nil
    end
end

function RStarSnapshot:clear_saved()
    self.events = {}
    super().clear_saved(self)
end

function RStarSnapshot:restore_impl()
    for i=#self.events, 1, -1 do
        local event = self.events[i]
        if event[1] == "add" then
            self.rstar:remove(event[2])
        elseif event[1] == "remove" then
            self.rstar:add(event[2], event[3], event[4])
        else
            error("unrachable")
        end
    end
    self.events = {}
end

function RStarSnapshot:reinit_impl()
    -- Do nothing.
end

function RStarSnapshot:cleanup_impl()
    self:unsubscribe()
end
