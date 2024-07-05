require "ui.containers.layout_frame"
require "ui.image"
require "ui.effects"

EffectFrame = {}

setup_class(EffectFrame, LayoutFrame)

function EffectFrame:__init(content)
    super().__init(self, content)
    self.hover_effect = effects.highlight()
    self.press_effect = effects.dim()
end

function EffectFrame:set_hover_effect(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element) => nil, or nil.")
    end
    self:_set_property("hover_effect", value)
end

function EffectFrame:set_press_effect(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element) => nil, or nil.")
    end
    self:_set_property("press_effect", value)
end

function EffectFrame:set_default_effect(value)
    if not is_type(value, "function", "nil") then
        self:_value_error("Value must be a function with the signature (element) => nil, or nil.")
    end
    self:_set_property("default_effect", value)
end

function EffectFrame:update()
    super().update(self)

    if self.content ~= nil and self.content:contains(unpack(self.mouse_pos)) then
        if love.mouse.isDown(1) then
            self.effect = self.press_effect
        else
            self.effect = self.hover_effect
        end
    else
        self.effect = self.default_effect
    end
end
