Converter = {
    convert = nil,
    convert_back = nil,
}
setup_class(Converter)

function Converter:__init(convert, convert_back)
    super().__init(self)

    if not is_type(convert, "function") then
        error("Expected convert to be a function, got "..details_string(convert)..".")
    end

    self.convert = convert
    self.convert_back = nil_coalesce(convert_back, convert)
end

function Converter:__call(...)
    return self:convert(...)
end

function Converter:__eq(other)
    if not is_type(other, Converter) then
        return false
    end
    return (other.convert == self.convert) and
           (other.convert_back == self.convert_back)
end
