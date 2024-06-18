
SnapshotFactory = {
    registered = {},

    register = function(typestring, class)
        SnapshotFactory.registered[typestring] = class
    end,

    build = function(x, shared_children)
        timer:push("SnapshotFactory:build("..type_string(x)..")")
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
            timer:pop(10)
            return nil
        end
        local snapshot = snapshot_class(x, shared_children)
        timer:pop(10)
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

    self.saved = {}
    self.saved_name_set = {}
    self.children = nil_coalesce(shared_children, {})
    self.deferred_children = (shared_children ~= nil)
end

function Snapshot:save(name, value)
    if self.saved_name_set[name] then
        error("A value ("..tostring(value)..") has already been saved under the name \""..name.."\"")
    end
    self.saved_name_set[name] = true
    self.saved[name] = value
    self:try_add_child_for(value)
end

function Snapshot:try_add_child_for(value)
    if value == nil then
        return
    end
    if self.children[value] == nil then
        self.children[value] = true -- Lock from recursion in snapshot constructor.
        local snapshot = SnapshotFactory.build(value, self.children)
        if snapshot ~= nil then
            self.children[value] = snapshot
        else
            self.children[value] = nil
        end
    end
end

function Snapshot:restore()
    timer:push(self:type()..":restore()")
    self:restore_impl()
    if not self.deferred_children then
        for _, child in pairs(self.children) do
            child:restore()
        end
    end
    timer:pop(10)
end

function Snapshot:clear_saved()
    timer:push(self:type()..":clear_saved()")
    self.saved = {}
    self.saved_name_set = {}
    if not self.deferred_children then
        for _, child in pairs(self.children) do
            child:clear_saved()
        end
    end
    timer:pop(10)
end

function Snapshot:reinit()
    timer:push(self:type()..":reinit()")
    self:clear_saved()
    if not self.deferred_children then

         -- Clean up any children who's saved values are no longer referenced.
        local weak_children = weak_table('k')
        timer:push(self:type()..":reinit()::shallow_copy")
        shallow_copy(self.children, weak_children)
        timer:poppush(10, self:type()..":reinit()::collectgarbage")
        self.children = nil
        collectgarbage()
        self.children = shallow_copy(weak_children)

        timer:poppush(10, self:type()..":reinit()::reinit_impl")
        for _, child in pairs(shallow_copy(self.children)) do
            child:reinit_impl()
        end
        timer:pop(10)
    end
    self:reinit_impl()
    timer:pop(10)
end

function Snapshot:cleanup()
    -- Allow the object to be garbage collected.
    timer:push(self:type()..":cleanup()")
    self:clear_saved()
    self:cleanup_impl()
    self.saved = nil
    self.saved_name_set = nil

    if not self.deferred_children then
        for _, child in pairs(self.children) do
            child:cleanup()
        end
    end
    timer:pop(10)
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
