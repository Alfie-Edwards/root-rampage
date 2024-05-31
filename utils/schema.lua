
BaseSchema = {
}
setup_class(BaseSchema)

function BaseSchema:__init()
    assert(self.complete ~= BaseSchema.complete)
    assert(self._match ~= BaseSchema._match)
    assert(self.__hash ~= BaseSchema.__hash)
end

function BaseSchema:__tostring()
    return hash(self)
end

function BaseSchema:__eq(other)
    if not is_type(other, BaseSchema) then
        return false
    end
    return hash(self) == hash(other)
end

function BaseSchema:match(x)
    local match, msg, path = self:_match(x, "x")
    if not match then
        return false, "Property "..path.." did not match schema: "..msg
    end
    return true
end

function BaseSchema:complete(x)
    error("Must be implemented in subclass.")
end

function BaseSchema:_match(x, path)
    error("Must be implemented in subclass.")
end

function BaseSchema:__hash()
    error("Must be implemented in subclass.")
end

function Schema(x)
    if is_type(x, BaseSchema) then
        return x
    end
    if type(x) == "table" then
        return TableSchema(x)
    end
    return PrimitiveSchema(x)
end

-------------------------------------------------------------------------------
-- Type
-------------------------------------------------------------------------------

TypeSchema = {
    t = nil,
    default = nil,
}
setup_class(TypeSchema, BaseSchema)

function TypeSchema:__init(t, default)
    super().__init(self)

    self.t = t
    self.default = default
end

function TypeSchema:complete(x)
    return nil_coalesce(x, self.default)
end

function TypeSchema:_match(x, path)
    if type_string(x) ~= self.t then
        return false, "Expected type "..self.t..", got "..type_string(x)..".", path
    end
    return true
end

function TypeSchema:__hash()
    return "type<"..self.t..">"
end

TypeSchema.STRING = TypeSchema("string", "")
TypeSchema.NUMBER = TypeSchema("number", 0)
TypeSchema.BOOL = TypeSchema("boolean", false)
TypeSchema.TABLE = TypeSchema("table", {})
TypeSchema.FUNCTION = TypeSchema("function", function() end)
TypeSchema.NIL = TypeSchema("nil", nil)

-------------------------------------------------------------------------------
-- Primitive
-------------------------------------------------------------------------------

PrimitiveSchema = {
    p = nil,
}
setup_class(PrimitiveSchema, BaseSchema)

function PrimitiveSchema:__init(p)
    super().__init(self)
    self.p = p
end

function PrimitiveSchema:complete(x)
    return nil_coalesce(x, self.p)
end

function PrimitiveSchema:__hash()
    return details_string(self.p)
end

function PrimitiveSchema:_match(x, path)
    if x ~= self.p then
        return false, "Expected "..details_string(p)..", got "..details_string(x)..".", path
    end
    return true
end

-------------------------------------------------------------------------------
-- Table
-------------------------------------------------------------------------------

TableSchema = {
    t = nil,
}
setup_class(TableSchema, BaseSchema)

function TableSchema:__init(t)
    super().__init(self)

    self.t = {}
    for k, v in pairs(t) do
        self.t[k] = Schema(v)
    end
end

function TableSchema:complete(x)
    x = nil_coalesce(x, {})
    if type(x) == "table" then
        for k, value_schema in pairs(self.t) do
            x[k] = value_schema:complete(x[k])
        end
    end
    return x
end

function TableSchema:_match(x, path)
    if type(x) ~= "table" then
        return false, "Expected table, got "..type(x)..".", path
    end
    for k, value_schema in pairs(self.t) do
        local match, msg, sub_path = value_schema:_match(x[k], path.."["..details_string(k).."]")
        if not match then
            return false, msg, sub_path
        end
    end
    return true
end

function TableSchema:__hash()
    local result = "{"
    for i, k in ipairs(keys_to_sorted_list(self.t)) do
        if i > 1 then
            result = result..","
        end
        result = result..details_string(k)..":"..hash(self.t[k])
    end
    result = result.."}"
    return result
end

function TableSchema:__pairs()
    local i, key
    return function(t, k)
        i, key = next(t, i)
        return key, self.t[key]
    end, keys_to_sorted_list(self.t), nil
end

-------------------------------------------------------------------------------
-- List
-------------------------------------------------------------------------------

ListSchema = {
    item_schema = nil,
}
setup_class(ListSchema, BaseSchema)

function ListSchema:__init(item_schema)
    super().__init(self)
    self.item_schema = Schema(item_schema)
end

function ListSchema:complete(x)
    x = nil_coalesce(x, {})
    if type(x) == "table" then
        for i, v in ipairs(x) do
            x[i] = self.item_schema:complete(x[i])
        end
    end
    return x
end

function ListSchema:_match(x, path)
    if not type(x) == "table" then
        return "Expected table, got "..type_string(x).."."
    end
    if not is_list(x) then
        return "Not a list (keys are not {1, 2, ..., n}).", path
    end
    for i, v in ipairs(x) do
        local match, msg, sub_path = self.item_schema:_match(v, path.."["..details_string(i).."]")
        if not match then
            return false, msg, sub_path
        end
    end
    return true
end

function ListSchema:__hash()
    return "["..hash(self.item_schema).."]"
end

-------------------------------------------------------------------------------
-- Map
-------------------------------------------------------------------------------

MapSchema = {
    key_schema = nil,
    item_schema = nil,
}
setup_class(MapSchema, BaseSchema)

function MapSchema:__init(key_schema, item_schema)
    super().__init(self)
    self.key_schema = Schema(key_schema)
    self.item_schema = Schema(item_schema)
end

function MapSchema:complete(x)
    x = nil_coalesce(x, {})
    if type(x) == "table" then
        for _, k in ipairs(keys_to_list(x)) do
            local v = x[k]
            x[k] = nil
            x[self.key_schema:complete(k)] = self.value_schema:complete(v)
        end
    end
    return x
end

function MapSchema:_match(x, path)
    if not type(x) == "table" then
        return "Expected table, got "..type_string(x).."."
    end
    for k, v in pairs(x) do
        local match, msg, sub_path = self.key_schema:_match(k, path..", key("..details_string(k)..")")
        if not match then
            return false, msg, sub_path
        end

        match, msg, sub_path = self.value_schema:_match(v, path.."["..details_string(k).."]")
        if not match then
            return false, msg, sub_path
        end
    end
    return true
end

function MapSchema:__hash()
    return "{"..hash(self.key_schema)..":"..hash(self.item_schema).."}"
end

-------------------------------------------------------------------------------
-- PatternSchema
-------------------------------------------------------------------------------

PatternSchema = {
    pattern = nil,
    default = nil,
}
setup_class(PatternSchema, BaseSchema)

function PatternSchema:__init(pattern, default)
    super().__init(self)

    self.pattern = pattern
    self.default = default
end

function PatternSchema:complete(x)
    return nil_coalesce(x, self.default)
end

function PatternSchema:_match(x, path)
    if not type(x) == "string" then
        return "Expected string, got "..type_string(x).."."
    end
    if string.find(x, "^"..self.pattern.."$") == nil then
        return false, "\""..x.."\" is not a valid hex code.", path
    end
    return true
end

function PatternSchema:__hash()
    return "pattern<"..self.pattern..">"
end

-------------------------------------------------------------------------------
-- AnyOf
-------------------------------------------------------------------------------

AnyOfSchema = {
    schemas = nil,
}
setup_class(AnyOfSchema, BaseSchema)

function AnyOfSchema:__init(...)
    super().__init(self)

    local schemas = {...}
    assert(#schemas > 0, "Must specify at least one schema.")

    self.schemas = {}
    for _, schema in ipairs(schemas) do
        table.insert(self.schemas, Schema(schema))
    end
end

function AnyOfSchema:complete(x)
    return self.schemas[1]:complete(x)
end

function AnyOfSchema:_match(x, path)
    if #schemas == 1 then
        return self.schemas[1].__match(x, path)
    end

    local error = "Did not match any schema:\n"
    for _, schema in ipairs(self.schemas) do
        local match, sub_error = schema:match(x)
        if match then
            return true
        else
            error = error..indent(sub_error, 3).."\n"
        end
    end
    return false, error, path
end

function AnyOfSchema:__hash()
    local result = "any_of<"
    for _, schema in ipairs(self.schemas) do
        result = result..hash(schema)..","
    end
    result = result..">"
    return result
end

-------------------------------------------------------------------------------
-- Enum
-------------------------------------------------------------------------------

EnumSchema = {}
setup_class(EnumSchema, AnyOfSchema)

function EnumSchema:__init(enum)
    super().__init(self, unpack(enum:values_list()))
end
