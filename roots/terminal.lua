require "utils"
require "roots.node"

Terminal = {
    RADIUS = 24,
    TIME = 5,
    TOOLTIP = "Hack terminal",
    TOOLTIP2 = "Gaining root access...",

    SPRITES = {
        unhacked = sprite.make_set("Terminal/", { "Terminal1.png","Terminal2.png" }),
        hacking = sprite.make_set("Terminal/", { "TerminalPlant1.png","TerminalPlant2.png" }),
        hacked = sprite.make_set("Terminal/", { "TerminalPlantFULLYHACKED1.png","TerminalPlantFULLYHACKED2.png" }),
    },

    GROW_DURATION = 2,
    WITHER_DURATION = 1,
    CYCLE_DURATION = 0.5,

    x = nil,
    y = nil,
    node = nil,
    roots = nil,
    t_hacked = nil,
    t_cut = nil,
}
setup_class("Terminal")

function Terminal.new(x, y)
    local obj = {}
    setup_instance(obj, Terminal)
    assert(x ~= nil)
    assert(y ~= nil)

    obj.x = x
    obj.y = y
    obj.t_hacked = never
    obj.t_cut = never

    return obj
end

function Terminal:create_node(parent)
    assert(self.node == nil)
    self.node = Node.new(self.x - 19, self.y - 8, parent, self.roots)
    self.node.is_terminal = true
    return self.node
end

function Terminal:sprite()
    if self.node ~= nil and self.t_hacked ~= never then
        if (t - self.t_hacked) < Terminal.GROW_DURATION then
            return sprite.sequence(Terminal.SPRITES.hacking, Terminal.GROW_DURATION, self.t_hacked)
        else
            return sprite.cycling(Terminal.SPRITES.hacked, Terminal.CYCLE_DURATION)
        end
    elseif self.t_cut ~= never and (t - self.t_cut) < Terminal.WITHER_DURATION then
        if self.t_hacked < Terminal.GROW_DURATION then
            return sprite.sequence(reverse(Terminal.SPRITES.hacking), Terminal.WITHER_DURATION, self.t_cut)
        else
            return sprite.cycling(Terminal.SPRITES.unhacked, Terminal.CYCLE_DURATION)
        end
    else
        return sprite.cycling(Terminal.SPRITES.unhacked, Terminal.CYCLE_DURATION)
    end

    return nil
end

function Terminal:update(dt)
    if self.node ~= nil and self.node.is_dead then
        self.node = nil
        self.t_hacked = never
        self.t_cut = t
    end
    if self.node ~= nil and self.t_hacked == never then
        self.t_hacked = t
        self.t_cut = never
    end
    if self.node == nil and
           self.roots.prospective.selection ~= nil and
           self.roots.prospective.message == nil and
           (self.x - self.roots.prospective.mouse_x) ^ 2 + (self.y - self.roots.prospective.mouse_y) ^ 2 < Terminal.RADIUS ^ 2 then
        self.roots.prospective.message = Terminal.TOOLTIP
    end
end

function Terminal:draw()
    local sprite = self:sprite()
    if sprite == nil then
        return
    end

    local ox = sprite:getWidth() / 2
    local oy = sprite:getHeight() / 2

    -- want to draw the sprite slightly above centre, since the 'ground' bit is near
    -- the bottom
    oy = oy - 5

    love.graphics.setColor({1, 1, 1, 1})
    love.graphics.draw(sprite, self.x, self.y, 0, 1, 1, ox, oy)
end