--[[
    This data structure was based on https://github.com/rick4stley/rstar, license below:

    The MIT license

    Copyright (c) 2021 Daniele Gurizzan

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

RStarBox = {
    x = nil,
    y = nil,
    w = nil,
    h = nil,
    item = nil,
}
setup_class(RStarBox)

function RStarBox:__init(x, y, w, h)
    super().__init(self)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 1
    self.h = h or 1
end

function RStarBox.union_many(bbs)
    local b = bbs[1].box
    local l = b.x
    local u = b.y
    local r = b.x + b.w
    local d = b.y + b.h

    local n = #bbs
    for i = 2, n do
        local x, y, w, h = bbs[i].box:unpack()

        l = math.min(l, x)
        u = math.min(u, y)
        r = math.max(r, x + w)
        d = math.max(d, y + h)
    end

    return l, u, (r - l), (d - u)
end

function RStarBox:position()
    return self.x, self.y
end

function RStarBox:dims()
    return self.w, self.h
end

function RStarBox:set(x, y, w, h)
    self.x = x or self.x
    self.y = y or self.y
    self.w = w or self.w
    self.h = h or self.h
end

function RStarBox:copy()
    return RStarBox(self:unpack())
end

function RStarBox:unpack()
    return self.x, self.y, self.w, self.h
end

function RStarBox:area()
    return self.w * self.h
end

function RStarBox:perimeter()
    return self.w * 2 + self.h * 2
end

function RStarBox:union(other)
    local ox, oy, ow, oh = other:unpack()
    local l = math.min(self.x, ox)
    local u = math.min(self.y, oy)
    local r = math.max(self.x + self.w, ox + ow)
    local d = math.max(self.y + self.h, oy + oh)

    return l, u, (r - l), (d - u)
end

function RStarBox:unionArea(other)
    local _, _, cw, ch = self:union(other)

    return cw * ch
end

function RStarBox:intersection_dims(other)
    local ow, oh = other:dims()
    local ux, uy, uw, uh = self:union(other)
    local ox = (self.w + ow) - uw
    local oy = (self.h + oh) - uh

    return ox, oy
end

function RStarBox:intersection_area(other)
    local ox, oy = self:intersection_dims(other)
    if ox <= 0 or oy <= 0 then
        return 0
    end
    return ox * oy
end

function RStarBox:center()
    return self.x + 0.5 * self.w, self.y + 0.5 * self.h
end

function RStarBox:intersects(other)
    local iw, ih = self:intersection_dims(other)
    return (iw >= 0) and (ih >= 0)
end

function RStarBox:contains(x, y)
    return (x >= self.x) and (x < self.x + self.w) and (y >= self.y) and (y < self.y + self.h)
end

function RStarBox:inrange(x, y, r)
    return self:sq_dist(x, y) <= (r * r)
end

function RStarBox:sq_dist(x, y)
    local clx, cly = clamp(x, self.x, self.x + self.w), clamp(y, self.y, self.y + self.h)

    return sq_dist(x, y, clx, cly)
end

function RStarBox:__tostring()
    return "{x: "..self.x..", y: "..self.y..", w: "..self.w..", h: "..self.h.."}"
end

RStarNode = {
    id = nil,
    is_leaf = nil,
    children = nil,
    box = nil,
    parent = nil,
    item = nil,
}
setup_class(RStarNode)

function RStarNode:__init(tree, is_leaf, child_1, child_2)
    self.id = tree.bid_counter
    self.is_leaf = is_leaf
    self.children = {}
    self.box = RStarBox()
    self.parent = nil

    tree.bid_counter = tree.bid_counter + 1

    if child_1 ~= nil then
        self.children[1] = child_1
        child_1.parent = self
        if child_2 ~= nil then
            self.children[2] = child_2
            child_2.parent = self
        end
        if is_leaf then
            for i = 1, #self.children do
                tree.entries[self.children[i].id] = self
            end
        end
        self.box:set(RStarBox.union_many(self.children))
    end
end

function RStarNode:isOverfilled(tree)
    return #self.children > tree.M
end

function RStarNode:isUnderfilled(tree)
    return #self.children < tree.m
end

function RStarNode:add(tree, child)
    table.insert(self.children, child)

    if #self.children == 1 then
        self.box:set(child.box:unpack())
    else
        self.box:set(self.box:union(child.box))
    end
    if not self.is_leaf then
        child.parent = self
    else
        tree.entries[child.id] = self
    end
end

function RStarNode:find(id)
    local found, i = false, 0
    while (not found) and i <= #self.children do
        i = i + 1
        found = self.children[i].id == id
    end
    return found, i
end

function RStarNode:remove(tree, entry_id)
    if self.is_leaf then
        local found, i = self:find(entry_id)
        if found then 
            local entry = table.remove(self.children, i)
            tree.entries[entry.id] = nil
            if #self.children > 0 then
                self.box:set(RStarBox.union_many(self.children))
            end
            return entry.box
        end
    end
end

function RStarNode:removeNode(node_id)
    if not self.is_leaf then
        local found, i = self:find(node_id)
        if found then 
            local node = table.remove(self.children, i)
            self.box:set(RStarBox.union_many(self.children))
            return node
        end
    end
end

function RStarNode:destroy()
    while #self.children > 0 do
        table.remove(self.children)
    end
    self.children = nil
    self.box = nil
end

function RStarNode:_chooseBranch(inserting, auxbox)
    local min_enlargement
    local chosen
    local children = self.children

    for i = 1, #children do
        auxbox:set(children[i].box:union(inserting.box))
        local enlargement = auxbox:area() - children[i].box:area()

        if i == 1 or enlargement < min_enlargement then
            min_enlargement = enlargement
            chosen = i
        elseif enlargement == min_enlargement and children[chosen].box:area() < children[i].box:area() then
            chosen = i
        end
    end

    return chosen
end

function RStarNode:_chooseLeaf(p, inserting, auxbox)
    local a = {}
    local n = #self.children

    for i = 1, n do
        auxbox:set(self.children[i].box:union(inserting.box))
        local enlargement = auxbox:area() - self.children[i].box:area()
        table.insert(a, {i, enlargement})
    end

    table.sort(a, function(a, b) return a[2] < b[2] end)

    local min_overlap
    local chosen
    local scan = math.min(p, n)
    for i = 1, scan do
        local pos = a[i][1]
        local current = self.children[pos]
        local overlap_sum = 0

        auxbox:set(current.box:union(inserting.box))
        for j = 1, n do
            if j ~= pos then
                overlap_sum = overlap_sum + (auxbox:intersection_area(self.children[j].box) - current.box:intersection_area(self.children[j].box))
            end
        end

        if i == 1 or overlap_sum < min_overlap then
            min_overlap = overlap_sum
            chosen = pos
        end
    end

    return chosen
end

RStar = {
    m = nil,
    M = nil,
    reinsert_p = nil,
    reinsert_method = nil,
    choice_p = nil,
    id_counter = nil,
    bid_counter = nil,
    height = nil,
    root = nil,
    entries = nil,
    overflow_mem = nil,
    len = nil,
    added = nil, -- added(item, x, y)
    removed = nil, -- removed(item, x, y)
}
setup_class(RStar)

function RStar:__init(settings)
    self.m = 8
    self.M = 20
    self.reinsert_p = 6
    self.reinsert_method = 1
    self.choice_p = 20
    self.id_counter = -1
    self.bid_counter = -1
    self.height = 0
    self.root = nil
    self.entries = {}
    self.overflow_mem = {}
    self.item_map = {}
    self.len = 0
    self.added = Event() -- added(x, y, obj)
    self.removed = Event() -- removed(x, y, obj)

    if settings then
        if type(settings.M) == 'number' then
            self.M = math.max(math.floor(settings.M), 4)
        end

        if type(settings.m) == 'number' then
            self.m = math.min(math.max(math.floor(settings.m), 2), math.floor(self.M * 0.5))
        end

        if type(settings.reinsert_p) == 'number' then
            local f = math.floor(settings.reinsert_p)
            if f > 0 and f < self.M then
                self.reinsert_p = f
            end
        end

        if settings.reinsert_method == 'weighted' then
            self.reinsert_method = 2
        end

        if type(settings.choice_p) == 'number' then
            self.choice_p = math.min(math.floor(settings.choice_p), self.M)
        else
            self.choice_p = self.M
        end
    end
end

function RStar:add(item, x, y)
    timer:push("RStar:add")
    self.id_counter = self.id_counter + 1
    local new_entry = {id = self.id_counter, box = RStarBox(x, y, 0, 0), item=item }

    if self.height == 0 then
        self.root = RStarNode(self, true, new_entry)
        self.height = 1
    else
        self:_insert(new_entry, 0)
        for i = 0, self.height do
            self.overflow_mem[i] = nil
        end
    end

    self.item_map[item] = id_counter
    self.len = self.len + 1
    self.added(item, x, y)
    timer:pop(10)
end

function RStar:remove(item)
    timer:push("RStar:remove")
    local id = self.item_map[item]
    if id == nil or self.entries[id] == nil then return end

    local n = self.entries[id]
    local removed = n.box
    self.entries[id]:remove(self, id)
    local q = {}
    local lc = 0

    while n.parent ~= nil do
        local p = n.parent

        if n:isUnderfilled(self) then
            local nr = p:removeNode(n.id)
            table.insert(q, {lc, nr})
        else
            p.box:set(RStarBox:union_many(p.children))
        end

        lc = lc + 1
        n = p
    end

    while #q > 0 do
        local level, node = unpack(table.remove(q))

        while #node.children > 0 do
            self:_insert(table.remove(node.children), level)
        end

        node:destroy()
    end

    if (not self.root.is_leaf) and #self.root.children == 1 then
        local old = self.root
        self.root = old.children[1]
        self.root.parent = nil
        old:destroy()
        self.height = self.height - 1
    end

    if self.root.is_leaf and #self.root.children == 0 then
        self.root:destroy()
        self.root = nil
        self.height = 0
    end

    self.item_map[item] = nil
    self.len = self.len - 1
    self.removed(item, n.box.x, n.box.y)
    timer:pop(10)
end

function RStar:any()
    return self.len > 0
end

function RStar:in_bounds(x1, y1, x2, y2)
    timer:push("RStar:in_bounds")
    local result = {}
    local result_nodes = self:_in_bounds(x1, y1, x2, y2)
    for i, v in ipairs(result_nodes) do
        result[i] = v.item
    end
    timer:pop(10)
    return result
end

function RStar:_in_bounds(x1, y1, x2, y2)
    local s = RStarBox(math.min(x1, x2), math.min(y1, y2), math.abs(x2 - x1), math.abs(y2 - y1))
    local result = {}
    if self.root then
        local traverse = { self.root }

        while #traverse > 0 do
            local first = table.remove(traverse, 1)

            for i = 1, #first.children do
                if s:intersects(first.children[i].box) then
                    table.insert(first.is_leaf and result or traverse, first.children[i])
                end
            end
        end
    end
    return result
end

function RStar:in_radius(x, y, r)
    timer:push("RStar:in_radius")
    local result_nodes = self:_in_radius(x, y, r)
    local result = {}
    for i, v in ipairs(result_nodes) do
        result[i] = v.item
    end
    timer:pop(10)
    return result
end

function RStar:_in_radius(x, y, r)
    local result = {}
    if self.root then
        local traverse = { self.root }
        local r2 = r * r

        while #traverse > 0 do
            local first = table.remove(traverse, 1)

            for i = 1, #first.children do
                if first.is_leaf then
                    if sq_dist(first.children[i].box.x, first.children[i].box.y, x, y) < r2 then
                        table.insert(result, first.children[i])
                    end
                elseif first.children[i].box:inrange(x, y, r) then
                    table.insert(traverse, first.children[i])
                end
            end
        end
    end
    return result
end

function RStar:any_in_radius(x, y, r)
    timer:push("RStar:any_in_radius")
    if self.root then
        local traverse = { self.root }

        while #traverse > 0 do
            local first = table.remove(traverse, 1)

            for i = 1, #first.children do
                if first.children[i].box:inrange(x, y, r) then
                    if first.is_leaf then
                        timer:pop(10)
                        return true
                    end
                    table.insert(traverse, first.children[i])
                end
            end
        end
    end
    timer:pop(10)
    return false
end

function RStar:closest(x, y)
    timer:push("RStar:closest")
    local queue = PriorityQueue.new()
    local enqueue = function(node)
        queue:enqueue(node, node.box:sq_dist(x, y))
    end
    enqueue(self.root)

    while queue:len() do
        local current, _ = queue:dequeue()
        if current.item ~= nil then
            timer:pop(10)
            return current.item
        end
        for _, child in ipairs(current.children) do
            enqueue(child)
        end
    end
    timer:pop(10)
    return nil
end

RStar._distanceSort = {
    function(node)
        local d = {}
        local mx, my = node.box:center()
        local children = node.children
    
        while #children > 0 do
            local r = table.remove(children)
            local cx, cy = r.box:center()
            local dx, dy = cx - mx, cy - my
            table.insert(d, {r, math.sqrt(dx*dx + dy*dy)})
        end
    
        table.sort(d, function(a, b) return a[2] > b[2] end)
        return d
    end,
    function(node)
        local d = {}
        local sx, sy = 0, 0
        local children = node.children

        for i = 1, #children do
            local cx, cy = children[i].box:center()
            sx = sx + cx
            sy = sy + cy
        end
        local mx, my = sx / #children, sy / #children
    
        while #children > 0 do
            local r = table.remove(children)
            local cx, cy = r.box:center()
            local dx, dy = cx - mx, cy - my
            table.insert(d, {r, math.sqrt(dx*dx + dy*dy)})
        end
    
        table.sort(d, function(a, b) return a[2] > b[2] end)
        return d
    end,
}

RStar._axisSort = {
    {
        function(a, b) return a.box.x < b.box.x end,
        function(a, b) return a.box.y < b.box.y end,
    },
    {
        function(a, b) return a.box.x + a.box.w < b.box.x + b.box.w end,
        function(a, b) return a.box.y + a.box.h < b.box.y + b.box.h end,
    },
}

function RStar:_determineSplit(node)
    local auxbox = RStarBox()
    local aux = {}
    local dist = self.M - 2*self.m + 2
    local s = {0, 0}
    local min_overlap, min_area
    local chosen, chosen_dist
    local dists = {{},{}}
    local children = node.children
    for i = 1, 2 do
        local sw = {0, 0}

        for w = 1, 2 do

            table.sort(children, RStar._axisSort[i][w])

            for k = 1, dist do
                if k == 1 then
                    for j = 1, self.m do
                        table.insert(aux, table.remove(children, 1))
                    end
                else
                    table.insert(aux, table.remove(children, 1))
                end

                node.box:set(RStarBox.union_many(aux))
                auxbox:set(RStarBox.union_many(children))
                local first_p = node.box:perimeter()
                local second_p = auxbox:perimeter()
                local overlap = node.box:intersection_area(auxbox)
                local area = node.box:area() + auxbox:area()

                if k == 1 or overlap < min_overlap then
                    min_overlap = overlap
                    if k > 1 then
                        min_area = (min_area == nil and area) or (area < min_area and area or min_area)
                    end
                    dists[i][w] = (self.m-1)+k
                elseif overlap == min_overlap and min_area and area < min_area then
                    min_area = area
                    dists[i][w] = (self.m-1)+k
                end

                sw[w] = sw[w] + first_p + second_p
            end

            while #aux > 0 do table.insert(children, table.remove(aux)) end
        end

        s[i] = sw[1] < sw[2] and sw[1] or sw[2]
        chosen_dist = sw[1] < sw[2] and 1 or 2
    end

    chosen = (s[1] < s[2] and 1 or 2)

    return chosen, chosen_dist, dists[chosen][chosen_dist]
end

function RStar:_split(node)
    local axis, value, distribution = self:_determineSplit(node)
    local theotherhalf = RStarNode(self, node.is_leaf)
    local children = node.children

    table.sort(children, RStar._axisSort[axis][value])

    while #children > distribution do
        theotherhalf:add(self, table.remove(children))
    end

    node.box:set(RStarBox.union_many(children))

    return theotherhalf
end

function RStar:_overflow(node, level)
    if level == self.height or self.overflow_mem[level] then
        return self:_split(node)
    else
        self.overflow_mem[level] = true
        self:_reinsert(node, level)
    end
end

function RStar:_reinsert(node, level)
    local sorted = RStar._distanceSort[self.reinsert_method](node)
    local j = 0
    local reinserting = {}

    for i = 0, self.reinsert_p-1 do
        table.insert(reinserting, table.remove(sorted, self.reinsert_p - i)[1])
    end

    while #sorted > 0 do
        node:add(self, table.remove(sorted)[1])
    end

    while #reinserting > 0 do
        self:_insert(table.remove(reinserting, 1), level)
    end
end

function RStar:_chooseSubtree(node, level)
    local n = self.root
    local auxbox = RStarBox()

    for i = 1, self.height - level - 1 do
        if n.children[1].is_leaf then
            n = n.children[n:_chooseLeaf(self.choice_p, node, auxbox)]
        else
            n = n.children[n:_chooseBranch(node, auxbox)]
        end
    end

    return n
end

function RStar:_insert(node, level)
    local container = self:_chooseSubtree(node, level)
    container:add(self, node)

    while container ~= nil do
        local new_half = nil
        if container:isOverfilled(self) then
            new_half = self:_overflow(container, level)
        end

        if new_half ~= nil then
            if container.parent == nil then
                self.root = RStarNode(self, false, container, new_half)
                self.height = self.height + 1
                container = self.root
            else
                container.parent:add(self, new_half)
            end
        elseif container.parent then
            container.parent.box:set(RStarBox.union_many(container.parent.children))
        end

        container = container.parent
        level = level + 1
    end
end

function RStar:draw(draw_boxes, draw_nodes)
    local lc = {
        {1,0,0,0.7},
        {0,1,1,0.7},
        {1,1,0,0.7},
        {1,0,1,0.7},
        {0,0,1,0.7}
    }
    if self.root and self.height <= 5 and (draw_boxes ~= false or draw_nodes ~= false) then
        local traverse = { self.root }
        local thislevel = 1
        local nextlevel = 1
        local level = 0

        while #traverse > 0 do
            local first = table.remove(traverse, 1)
            thislevel = thislevel - 1

            if thislevel == 0 then
                level = level + 1
                thislevel = nextlevel
                nextlevel = 0
            end

            if draw_nodes ~= false then
                love.graphics.setLineWidth(1)
                love.graphics.setColor(lc[level])
                love.graphics.rectangle('line', first.box:unpack())
            end

            if first.is_leaf then
                if draw_boxes ~= false then
                    love.graphics.setColor(1,1,1,0.7)

                    for i = 1, #first.children do
                        love.graphics.points(first.children[i].box.x, first.children[i].box.y)
                    end
                end
            else
                for i = 1, #first.children do
                    table.insert(traverse, first.children[i])
                end
                nextlevel = nextlevel + #first.children
            end
        end
    end
end
