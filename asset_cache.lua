
AssetCache = {
    images = nil,
    image_data = nil,
    fonts = nil,
    sounds = nil,
}
setup_class(AssetCache)

function AssetCache.new()
    local obj = magic_new()

    obj.images = {}
    obj.image_data = {}
    obj.fonts = {}
    obj.sounds = {}

    return obj
end

function AssetCache:get_image(name, extension)
    name = name.."."..(extension or "png")
    if self.images[name] == nil then
        self.images[name] = love.graphics.newImage("assets/"..name)
    end
    return self.images[name]
end

function AssetCache:get_image_data(name, extension)
    name = name.."."..(extension or "png")
    if self.image_data[name] == nil then
        self.image_data[name] = love.image.newImageData("assets/"..name)
    end
    return self.image_data[name]
end

function AssetCache:get_font(name, extension, size)
    name = name.."."..(extension or "ttf")
    size = size or 8
    if self.fonts[name] == nil then
        self.fonts[name] = love.graphics.newFont("assets/"..name, size, "none")
        self.fonts[name]:setFilter("nearest", "nearest", size)
    end
    return self.fonts[name]
end

function AssetCache:get_mp3(name, mode)
    return self:get_sound(name, "mp3", mode)
end

function AssetCache:get_sound(name, extension, mode)
    name = name.."."..(extension or "mp3")
    if self.sounds[name] == nil then
        self.sounds[name] = love.audio.newSource("assets/"..name, mode or "static")
    end
    return self.sounds[name]
end
