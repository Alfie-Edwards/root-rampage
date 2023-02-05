require "utils"
require "hacking"

Wincon = {
    game_over = nil,
    end_screen = nil,
}
setup_class("Wincon")

function Wincon.new(roots, hacking)
    local obj = {}
    setup_instance(obj, Wincon)

    assert(roots ~= nil)
    assert(hacking ~= nil)
    obj.roots = roots
    obj.hacking = hacking
    obj.game_over = false

    return obj
end

function Wincon:RootsWin()
    self.game_over = true
    self.end_screen = "ROOTS WIN"
end

function Wincon:AxeManWins()
    self.game_over = true
    self.end_screen = "AXE MAN WINS"
end

function Wincon:update(dt)
    if self.hacking:get_progress() >= Hacking.MAX then
        self:RootsWin()
    elseif #(self.roots.nodes) == 0 then
        self:AxeManWins()
    end
end

function Wincon:draw()
    if not self.game_over then
        return
    end
    love.graphics.clear({0, 0, 0, 1})
    draw_centred_text(self.end_screen, canvas:width() / 2, canvas:height() / 2, {1, 1, 1, 1})
end