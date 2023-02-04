require "roots.branch"

Node = {
    parent = nil,
    children = nil,
    is_tree = nil,
    is_dead = nil,
    roots = nil,
}
setup_class("Node")

function Node.new(x, y, parent, is_tree, roots)
    local obj = {}
    setup_instance(obj, Node)

    assert(roots ~= nil)

    if is_tree == nil then
        is_tree = false
    end

    obj.x = x
    obj.y = y
    obj.children = {}
    obj.is_tree = is_tree
    obj.is_dead = false

    if parent == nil then
        assert(is_tree)
        roots:add_branch(Branch.new(obj, 1))
    else
        parent:add_child(obj)
    end

    roots:add_node(obj)
    return obj
end

function Node:add_child(child)
    assert(child ~= nil)
    table.insert(self.children, child)
    child.parent = self
    if #self.children > 1 then
        self.roots:add_branch(Branch.new(self, #self.children))
    end
end

function Node:remove_child(child)
    assert(child ~= nil)
    assert(child.parent == self)
    local key = get_key(self.children, child)
    self.children[key] = nil
end

function Node:get_children()
    local children = {}
    local i = 0
    for _,child in pairs(self.children) do
      i = i + 1
      children[i] = child
    end

    return children
end

function get_main_branch()
    -- Get the branch this node was originally created on.
    local base
    local child_index

    if base.parent == nil then
        base = self
        child_index = 1
    else
        local prev = self
        base = base.parent
        while (#base.children) == 1 and base.parent ~= nil do
            base = base.parent
        end

        child_index = get_key(base.children, prev)
    end

    local branch = self.roots.get_branch(base, child_index)
    assert(branch ~= nil)
    return branch
end

function Node:find_root_node()
    local root = self
    while root.parent ~= nil do
        root = root.parent
    end
    return root
end

function Node:do_to_subtree(func)
    assert(func ~= nil)
    func(self)
    for _,child in ipairs(self.children) do
        child:do_to_subtree(func)
    end
end

function Node:kill_subtree_if_no_trees()
    local any_trees = function(node)
        if node.is_tree then
            return true
        else
            for _,child in ipairs(node.children) do
                if any_trees(child) then
                    return true
                end
            end
            return false
        end
    end

    if any_trees(self) then
        self:do_to_subtree(
            function(node)
                node:kill()
            end
        )
    end
end

function Node:cut()
    -- Update all branches starting at this node.
    for _,branch in ipairs(self.roots.get_branches(self)) do
        branch:trim_start()
    end

    -- Start a new branch after this node.
    if self.parent ~= nil and #self.children > 0 then
        self.roots.add_branch(Branch.new(self.children[1], 1))
        self:get_main_branch():trim_end_to(self.parent)
    end

    -- Cache children and parent.
    local children = self:get_children()
    local parent = self.parent

    -- Disconnect node.
    self:remove_all_children()
    if self.parent ~= nil then
        self.parent.remove_child(self)
    end

    -- Kill check on parent graph.
    if parent ~= nil then
        parent:find_root_node():kill_subtree_if_no_trees()
    end

    -- Kill check on child graphs.
    for _,child in ipairs(children) do
        child:kill_subtree_if_no_trees()
    end

    self:kill()

    -- Create branch containing just this node.
    self.roots:add_branch(Branch.new(self, 1))
end

function Node:kill()
    self.is_dead = true
end
