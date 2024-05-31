require "ui.converter"

BindingMode = Enum("ONE_WAY", "TWO_WAY")

Binding = {
    _mode = nil,

    src_handler = nil,
    dst_handler = nil,
    src_event = nil,
    dst_event = nil,

    src = nil,
    dst = nil,
    src_prop = nil,
    dst_prop = nil,
    converter = nil,
}
setup_class(Binding, GetterSetterPropertyTable)

function Binding:__init(mode, ...)
    super().__init(self)

    if not BindingMode:is(mode) then
        self:_value_error("Value must be one of "..tostring(BindingMode)..".", "mode", mode)
    end

    self._mode = mode

    self.src_handler = function(src, property_name, old_value, new_value)
        if src ~= self.src or property_name ~= self.src_prop then
            return
        end
        if self.converter then
            new_value = self.converter.convert(new_value)
        end
        self.dst[self.dst_prop] = new_value
    end

    self.dst_handler = function(dst, property_name, old_value, new_value)
        if dst ~= self.dst or property_name ~= self.dst_prop then
            return
        end
        if self.converter then
            new_value = self.converter.convert_back(new_value)
        end
        self.src[self.src_prop] = new_value
    end

    local nargs = #{...}
    if nargs > 5 then
        error("Expected at most 5 arguments, got "..tostring(nargs)..":", ...)
    elseif nargs > 3 then
        self.src, self.src_prop, self.dst, self.dst_prop, self.converter = ...
    else
        self.src, self.src_prop, self.converter = ...
    end
end

function Binding:get_mode()
    return self._mode
end

function Binding:set_src(value)
    if not (value == nil or value.property_changed ~= nil) then
        self:_value_error("Value must implement a property_changed event (src, property_name, old_value, new_value), or be nil.")
    end
    if self:_set_property("src", value) then
        self:update_subcriptions()
    end
end

function Binding:set_dst(value)
    if (self.mode == BindingMode.TWO_WAY) and (value ~= nil) and (value.property_changed == nil) then
        self:_value_error("When using binding mode "..self.mode..", value must implement a property_changed event (dst, property_name, old_value, new_value), or be nil.")
    end
    if self:_set_property("dst", value) then
        self:update_subcriptions()
    end
end

function Binding:set_src_prop(value)
    if not is_type(value, "string", "nil") then
        self:_value_error("Value must be a string, or nil.")
    end
    if self:_set_property("src_prop", value) then
        self:update_subcriptions()
    end
end

function Binding:set_dst_prop(value)
    if not is_type(value, "string", "nil") then
        self:_value_error("Value must be a string, or nil.")
    end
    if self:_set_property("dst_prop", value) then
        self:update_subcriptions()
    end
end

function Binding:set_converter(value)
    if not is_type(value, "function", "Converter", "nil") then
        self:_value_error("Value must be a function, a Converter, or nil.")
    end
    if is_type(value, "function") then
        value = Converter(value)
    end
    if self:_set_property("converter", value) then
        self:update_subcriptions()
    end
end

function Binding:apply()
    if self.src == nil then
        error("Cannot apply binding when src is nil")
    elseif self.dst == nil then
        error("Cannot apply binding when dst is nil")
    elseif self.src_prop == nil then
        error("Cannot apply binding when src_prop is nil")
    elseif self.dst_prop == nil then
        error("Cannot apply binding when dst_prop is nil")
    end

    self.src_handler(self.src, self.src_prop, self.src[self.src_prop], self.src[self.src_prop])
end

function Binding:unbind()
    self:_unsubscribe()
end

function Binding:update_subcriptions()
    self:_unsubscribe()
    if (self.src ~= nil) and (self.dst ~= nil) and (self.src_prop ~= nil) and (self.dst_prop ~= nil) then
        self:_subscribe()
    end
end

function Binding:_subscribe()
    if self.src ~= nil then
        self.src_event = self.src.property_changed
        self.src_event:subscribe(self.src_handler)
    end

    if self.mode == BindingMode.TWO_WAY and self.dst ~= nil then
        self.dst_event = self.dst.property_changed
        self.dst_event:subscribe(self.dst_handler)
    end
end

function Binding:_unsubscribe()
    if self.src_event ~= nil then
        self.src_event:unsubscribe(self.src_handler)
        self.src_event = nil
    end
    if self.mode == BindingMode.TWO_WAY and self.dst_event ~= nil then
        self.dst_event:unsubscribe(self.dst_handler)
        self.dst_event = nil
    end
end

OneWayBinding = {}

setup_class(OneWayBinding, Binding)

function OneWayBinding:__init(...)
    super().__init(self, BindingMode.ONE_WAY, ...)
end

TwoWayBinding = {}

setup_class(TwoWayBinding, Binding)

function TwoWayBinding:__init(...)
    super().__init(self, BindingMode.TWO_WAY, ...)
end
