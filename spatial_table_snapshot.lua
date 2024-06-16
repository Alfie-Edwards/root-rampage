require "snapshot"

SpatialTableSnapshot = {
    points = nil,
    events = nil,
    add_handler = nil,
    remove_handler = nil,
}
setup_class(SpatialTableSnapshot, Snapshot)
SnapshotFactory.register("SpatialTable", SpatialTableSnapshot)

-- A snapshot class specialised for State objects.
-- Avoid duplicating the whole state by only saving values which change.
function SpatialTableSnapshot:__init(points, shared_children)
    super().__init(self, shared_children)

    assert(points ~= nil)
    self.points = points
    self.events = {}
    self:subscribe()
end

function SpatialTableSnapshot:subscribe()
    self:unsubscribe()
    self.add_handler = function(x, y, obj)
        table.insert(self.events, {"add", x, y, obj})
    end
    self.remove_handler = function(x, y, obj)
        table.insert(self.events, {"remove", x, y, obj})
    end
    self.points.added:subscribe(self.add_handler)
    self.points.removed:subscribe(self.remove_handler)
end

function SpatialTableSnapshot:unsubscribe()
    if self.add_handler ~= nil then
        self.points.added:unsubscribe(self.add_handler)
        self.add_handler = nil
    end
    if self.remove_handler ~= nil then
        self.points.removed:unsubscribe(self.remove_handler)
        self.remove_handler = nil
    end
end

function SpatialTableSnapshot:restore_impl()
    for i=#self.events, 1, -1 do
        local event = self.events[i]
        if event[1] == "add" then
            self.points:remove(event[2], event[3], event[4])
        elseif event[1] == "remove" then
            self.points:add(event[2], event[3], event[4])
        else
            error("unrachable")
        end
    end
    self.events = {}
end

function SpatialTableSnapshot:cleanup_impl()
    self:unsubscribe()
end
