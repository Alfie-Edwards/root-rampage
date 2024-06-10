
AssetCache = {
    images = nil,
    image_data = nil,
    fonts = nil,
    sounds = nil,
}
setup_class(AssetCache)

function AssetCache:__init()
    super().__init(self)

    self.images = {}
    self.image_data = {}
    self.fonts = {}
    self.sounds = {}
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
    key = name.."["..size.."]"
    if self.fonts[key] == nil then
        self.fonts[key] = love.graphics.newFont("assets/"..name, size, "none")
        self.fonts[key]:setFilter("nearest", "nearest", size)
    end
    return self.fonts[key]
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
