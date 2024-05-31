require "ui.layout_element"
require "ui.image"

TripleButtonState = Enum("DEFAULT", "HOVER", "CLICK")

TripleButton = {
    default_image = nil,
    hover_image = nil,
    click_image = nil,

    active_image = nil,
    active_image_elem = nil,
}

setup_class(TripleButton, LayoutElement)

function TripleButton:__init()
    super().__init(self)

    self.active_image_elem = Image()
    self:_add_visual_child(self.active_image_elem)
end

function TripleButton:set_default_image(value)
    if not is_type(value, "Texture", "nil") then
        self:_value_error("Value must be a love.graphics.Texture, a love.graphics.Image, or nil.")
    end
    if self:_set_property("default_image", value) then
        self:update_layout()
    end
end

function TripleButton:set_hover_image(value)
    if not is_type(value, "Texture", "nil") then
        self:_value_error("Value must be a love.graphics.Texture, a love.graphics.Image, or nil.")
    end
    if self:_set_property("hover_image", value) then
        self:update_layout()
    end
end

function TripleButton:set_click_image(value)
    if not is_type(value, "Texture", "nil") then
        self:_value_error("Value must be a love.graphics.Texture, a love.graphics.Image, or nil.")
    end
    if self:_set_property("click_image", value) then
        self:update_layout()
    end
end

function TripleButton:set_override_state(value)
    if not (value == nil or TripleButtonState:is(value)) then
        self:_value_error("Value must be a one of "..tostring(TripleButtonState)..", or nil")
    end
    if self:_set_property("override_state", value) then
        self:update_layout()
    end
end

function TripleButton:toggle()
    local temp = self.default_image
    self.default_image = self.click_image
    self.click_image = temp
end

function TripleButton:mousemoved(x, y, dx, dy)
    if self.override_state == nil and self:contains(x, y) then
        if love.mouse.isDown(1) then
            self.active_image_elem.image = self.click_image
        else
            self.active_image_elem.image = self.hover_image
        end
    end
end

function TripleButton:update(dt)
    local mouse_x, mouse_y = unpack(self.mouse_pos)
    if self.override_state ~= nil then
        if self.override_state == TripleButtonState.DEFAULT then
            self.active_image_elem.image = self.default_image
        elseif self.override_state == TripleButtonState.HOVER then
            self.active_image_elem.image = self.hover_image
        elseif self.override_state == TripleButtonState.CLICK then
            self.active_image_elem.image = self.click_image
        end
    elseif not self:contains(mouse_x, mouse_y) then
        self.active_image_elem.image = self.default_image
    end

    self.active_image_elem.width = self.bb:width()
    self.active_image_elem.height = self.bb:height()
end
