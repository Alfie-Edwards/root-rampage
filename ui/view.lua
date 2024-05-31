require "ui.element"

View = {
    content = nil,
    mouse_pos = nil,
}
setup_class(View)

function View:__init(width, height)
    super().__init(self)

    self.mouse_pos = {love.mouse.getPosition()}
end

function View:get_content()
    return self.content
end

function View:set_content(value)
    self.content = value
end

function View:mousepressed(x, y, button)
    local function mousepressed(element, x, y)
        -- Transform position into local coords.
        local transform = love.math.newTransform()
        transform:translate(element.bb.x1, element.bb.y1)
        if element.transform ~= nil then
            transform:apply(element.transform)
        end
        x, y = transform:inverseTransformPoint(x, y)

        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            if mousepressed(element._visual_children[i], x, y) then
                return true
            end
        end

        if not element:contains(x, y) then
            return false
        end

        local result = false
        if element.mousepressed ~= nil then
            result = element:mousepressed(x, y, button)
        end
        if result == nil then
            -- If a handler is set, assume it is consuming the event if not expicitly stated.
            result = true
        end
        return result
    end

    if self.content ~= nil then
        mousepressed(self.content, x, y)
    end
end

function View:mousereleased(x, y, button)
    local function mousereleased(element, x, y)
        -- Transform position into local coords.
        local transform = love.math.newTransform()
        transform:translate(element.bb.x1, element.bb.y1)
        if element.transform ~= nil then
            transform:apply(element.transform)
        end
        x, y = transform:inverseTransformPoint(x, y)

        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            if mousereleased(element._visual_children[i], x, y) then
                return true
            end
        end

        if not element:contains(x, y) then
            return false
        end

        local result = false
        if element.mousereleased ~= nil then
            result = element:mousereleased(x, y, button)
        end
        if result == nil then
            -- If a handler is set, assume it is consuming the event if not expicitly stated.
            result = true
        end
        return result
    end

    if self.content ~= nil then
        mousereleased(self.content, x, y)
    end
end

function View:keypressed(key)
    local function keypressed(element)
        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            if keypressed(element._visual_children[i]) then
                return true
            end
        end

        local result = false
        if element.keypressed ~= nil then
            result = element:keypressed(key)
        end
        if result == nil then
            -- If a handler is set, assume it is consuming the event if not expicitly stated.
            result = true
        end
        return result
    end

    if self.content ~= nil then
        keypressed(self.content)
    end
end

function View:textinput(t)
    local function textinput(element)
        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            if textinput(element._visual_children[i]) then
                return true
            end
        end

        local result = false
        if element.textinput ~= nil then
            result = element:textinput(t)
        end
        if result == nil then
            -- If a handler is set, assume it is consuming the event if not expicitly stated.
            result = true
        end
        return result
    end

    if self.content ~= nil then
        textinput(self.content)
    end
end

function View:update_cursor()
    local cursor = nil

    local function get_cursor(element)
        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            local child_cursor = get_cursor(element._visual_children[i])
            if child_cursor ~= nil then
                return child_cursor
            end
        end

        local x, y = unpack(element.mouse_pos)
        if not element:contains(x, y) then
            return nil
        end

        -- Handle cursor setting.
        return element.cursor
    end

    if self.content ~= nil then
        cursor = get_cursor(self.content)
    end

    if cursor == nil then
        cursor = love.mouse.getSystemCursor("arrow")
    end

    if love.mouse.getCursor() ~= cursor then
        love.mouse.setCursor(cursor)
    end
end

function View:update_mouse_pos(x, y)
    local function update_mouse_pos(element, x, y)
        -- Transform position into local coords.
        local transform = love.math.newTransform()
        transform:translate(element.bb.x1, element.bb.y1)
        if element.transform ~= nil then
            transform:apply(element.transform)
        end
        x, y = transform:inverseTransformPoint(x, y)

        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            update_mouse_pos(element._visual_children[i], x, y)
        end

        element.mouse_pos = {x, y}
    end

    if self.content ~= nil then
        cursor = update_mouse_pos(self.content, x, y)
    end
end

function View:mousemoved(x, y, dx, dy)
    self.mouse_pos = {x, y}
    self:update_mouse_pos(x, y)

    local function mousemoved(element)
        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            if mousemoved(element._visual_children[i]) then
                return true
            end
        end

        local local_x, local_y = unpack(element.mouse_pos)
        if not element:contains(local_x, local_y) then
            return false
        end

        -- Handle mousemoved.
        if element.mousemoved ~= nil then
            local result = element:mousemoved(local_x, local_y, dx, dy)
            if result or (result == nil) then
                -- If a handler is set, assume it is consuming the event if not expicitly stated.
                return true
            end
        end

        return false
    end

    if self.content ~= nil then
        mousemoved(self.content, x, y)
    end
end

function View:wheelmoved(x, y)
    local function wheelmoved(element)
        -- Iterate from topmost element down.
        for i = #(element._visual_children), 1, -1 do
            if wheelmoved(element._visual_children[i]) then
                return true
            end
        end

        local local_x, local_y = unpack(element.mouse_pos)
        if not element:contains(local_x, local_y) then
            return false
        end

        -- Handle mousemoved.
        if element.wheelmoved ~= nil then
            local result = element:wheelmoved(x, y)
            if result or (result == nil) then
                -- If a handler is set, assume it is consuming the event if not expicitly stated.
                return true
            end
        end

        return false
    end

    if self.content ~= nil then
        wheelmoved(self.content, x, y)
    end
end

function View:update(dt)

    -- Update elements in tree.
    local function update(element)
        element:update(dt)
        for _,child in ipairs(element._visual_children) do
            update(child)
        end
    end
    if self.content ~= nil then
        update(self.content)
    end

    self:update_mouse_pos(self.mouse_pos[1], self.mouse_pos[2])
    self:update_cursor()
end

function View:draw()
    -- Draw elements in tree.
    local scissor_stack = Stack()

    local function draw(element)
        if element.clip then
            local x, y = love.graphics.transformPoint(element.bb.x1, element.bb.y1)
            local x2, y2 = love.graphics.transformPoint(element.bb.x2, element.bb.y2)
            local w = x2 - x
            local h = y2 - y
            if love.graphics.getScissor() == nil then
                love.graphics.setScissor(x, y, w, h)
            else
                love.graphics.intersectScissor(x, y, w, h)
            end
        end
        scissor_stack:push({love.graphics.getScissor()})

        love.graphics.push()
        love.graphics.translate(element.bb.x1, element.bb.y1)

        if element.transform ~= nil then
            love.graphics.applyTransform(element.transform)
        end

        element:draw()

        for _,child in ipairs(element._visual_children) do
            draw(child)
        end

        scissor_stack:pop()
        if scissor_stack:head() ~= nil then
            love.graphics.setScissor(unpack(scissor_stack:head()))
        else
            love.graphics.setScissor()
        end
        love.graphics.pop()
    end

    if self.content ~= nil then
        draw(self.content)
    end
end
