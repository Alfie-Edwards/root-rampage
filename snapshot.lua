SnapshotFactory = {
    registered = {},

    register = function(typestring, class)
        SnapshotFactory.registered[typestring] = class
    end,

    build = function(x, shared_children)
        local x_class = class(x)
        local get_snapshot_class = function(c)
            if c == nil then
                return nil
            end
            return SnapshotFactory.registered[c:type()]
        end
        local snapshot_class = get_snapshot_class(x_class)
        while snapshot_class == nil and x_class ~= nil do
            x_class = super(x_class)
            snapshot_class = get_snapshot_class(x_class)
        end
        if x_class == nil then
            snapshot_class = SnapshotFactory.registered[type(x)]
        end
        if snapshot_class == nil then
            return nil
        end
        local snapshot = snapshot_class(x, shared_children)
        return snapshot
    end,
}

Snapshot = {
    saved = nil,
    saved_names_set = nil,
    children = nil,
}
setup_class(Snapshot)

-- Save the current properties of a state object so they can be restored later.
-- To avoid duplicating the whole state, only values which change are saved.
function Snapshot:__init(shared_children)
    super().__init(self)

    self.any_saved = false
    self.saved = {}
    self.saved_name_set = {}
    self.children = nil_coalesce(shared_children, weak_table('k'))
    self.deferred_children = (shared_children ~= nil)
end

function Snapshot:save(name, value)
    if self.saved_name_set[name] then
        error("A value ("..tostring(value)..") has already been saved under the name \""..tostring(name).."\"")
    end
    self.saved_name_set[name] = true
    self.any_saved = true
    self:try_add_child_for(name)

    if value ~= nil then
        self.saved[name] = value
        self:try_add_child_for(value)
    end
end

function Snapshot:try_add_child_for(value)
    if type(value) ~= "table" then
        return
    end
    if self.children[value] == nil then
        self.children[value] = true -- Lock from recursion in snapshot constructor.
        self.children[value] = SnapshotFactory.build(value, self.children)
    end
end

function Snapshot:restore()
    self:restore_impl()
    if not self.deferred_children then
        for _, child in pairs(self.children) do
            child:restore()
        end
    end
end

function Snapshot:clear_saved()
    if self.any_saved then
        self.saved = {}
        self.saved_name_set = {}
        self.any_saved = false
    end
    if not self.deferred_children then
        for _, child in pairs(self.children) do
            child:clear_saved()
        end
        collectgarbage('step', 0.1)
    end
end

function Snapshot:reinit()
    self:clear_saved()
    if not self.deferred_children then
        for _, child in pairs(shallow_copy(self.children)) do
            child:reinit_impl()
        end
    end
    self:reinit_impl()
    -- Memory leak tracking
    -- print(iter_size(self.children))
    -- local d = {}
    -- for k, _ in pairs(self.children) do
    --     local t = type_string(k)
    --     d[t] = nil_coalesce(d[t], 0) + 1
    -- end
    -- local n = {}
    -- for k, _ in pairs(d) do
    --     table.insert(n, k)
    -- end
    -- table.sort(n, function(a, b) return d[a] > d[b] end)
    -- for _, k in ipairs(n) do
    --     if d[k] > 1 then
    --         print(k..": "..d[k])
    --     end
    -- end
end

function Snapshot:cleanup()
    -- Allow the object to be garbage collected.
    self:clear_saved()
    self:cleanup_impl()
    self.saved = nil
    self.saved_name_set = nil

    if not self.deferred_children then
        for _, child in pairs(self.children) do
            child:cleanup()
        end
    end
end

function Snapshot:restore_impl()
    error("Snapshot classes must implement the `restore_impl` method.")
end

function Snapshot:cleanup_impl()
    error("Snapshot classes must implement the `cleanup_impl` method.")
end

function Snapshot:reinit_impl()
    error("Snapshot classes must implement the `reinit_impl` method.")
end
