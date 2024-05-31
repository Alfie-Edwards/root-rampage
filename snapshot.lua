
SnapshotFactory = {
    registered = {},

    register = function(typestring, class)
        SnapshotFactory.registered[typestring] = class
    end,

    build = function(x)
        local class = SnapshotFactory.registered[type_string(x)]
        if class == nil then
            return nil
        end
        return class(x)
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
function Snapshot:__init()
    super().__init(self)

    self.saved = {}
    self.saved_name_set = {}
    self.children = {}
end

function save(name, value)
    if self.saved_name_set[name] then
        error("A value ("..tostring(value)..") has already been saved under the name \""..name.."\"")
    end
    self.saved_name_set[name] = true
    self.saved[name] = value
    local snapshot = SnapshotFactory.build(value)
    if snapshot ~= nil then
        table.insert(self.children, snapshot)
    end
end

function Snapshot:restore()
    self:restore_impl()
    for _, child in ipairs(self.children) do
        child:restore()
    end
end

function Snapshot:cleanup()
    -- Allow the object to be garbage collected.
    self:cleanup_impl()
    self.saved = nil
    self.saved_name_set = nil
    for _, child in ipairs(self.children) do
        child:cleanup()
    end
end

function Snapshot:restore_impl()
    error("Snapshot classes must implement the `restore_impl` method.")
end

function Snapshot:cleanup_impl()
    error("Snapshot classes must implement the `cleanup_impl` method.")
end
