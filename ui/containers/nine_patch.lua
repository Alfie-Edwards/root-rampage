require "ui.containers.frame"
require "ui.image"
require "ui.effects"

NinePatch = {}

setup_class(NinePatch, Image)

function NinePatch:__init(image, content)
    super().__init(self)

    self._image_center_bb = BoundingBox()
    self._local_center_bb = BoundingBox()
    self._draw_args = {}
    self.frame = Frame()
    self._visual_children[1] = self.frame
    self:forward_property(self.frame, "content")

    self.image = image
    self.content = content
end

function NinePatch:update_layout()
    super().update_layout(self)

    if self.image ~= nil then
        local black = {0, 0, 0, 1}
        local max_x = self.image:getWidth() - 2
        local max_y = self.image:getHeight() - 2

        local function scan_x(y, default1, default2)
            local x1 = 1
            while not lists_equal({self.image:getPixel(x1, y)}, black) do
                x1 = x1 + 1
                if x1 > max_x then
                    default1 = nil_coalesce(default1, math.floor(max_x / 2))
                    default2 = nil_coalesce(default2, default1)
                    return default1, default2
                end
            end
            local x2 = x1
            while x2 < max_x and lists_equal({self.image:getPixel(x2 + 1, y)}, black) do
                x2 = x2 + 1
            end

            return x1, x2
        end

        local function scan_y(x, default1, default2)
            local y1 = 1
            while not lists_equal({self.image:getPixel(x, y1)}, black) do
                y1 = y1 + 1
                if y1 > max_y then
                    default1 = nil_coalesce(default1, math.floor(max_y / 2))
                    default2 = nil_coalesce(default2, default1)
                    return default1, default2
                end
            end
            local y2 = y1
            while y2 < max_y and lists_equal({self.image:getPixel(x, y2 + 1)}, black) do
                y2 = y2 + 1
            end

            return y1, y2
        end

        local ic = self._image_center_bb
        ic.x1, ic.x2 = scan_x(0)
        ic.y1, ic.y2 = scan_y(0)

        local lc = self._local_center_bb
        lc.x1 = ic.x1 - 1
        lc.y1 = ic.y1 - 1
        lc.x2 = self.bb:width() - (max_x - ic.x2)
        lc.y2 = self.bb:height() - (max_y - ic.y2)
        if lc.x1 > lc.x2 then
            local avg = (lc.x1 + lc.x2) * 0.5
            ic.x1 = ic.x1 + (avg - lc.x1)
            ic.x2 = ic.x2 - (lc.x2 - avg)
            lc.x1 = avg
            lc.x2 = avg
        end
        if lc.y1 > lc.y2 then
            local avg = (lc.y1 + lc.y2) * 0.5
            ic.y1 = ic.y1 + (avg - lc.y1)
            ic.y2 = ic.y2 - (lc.y2 - avg)
            lc.y1 = avg
            lc.y2 = avg
        end
        local xmin = math.min(ic.x1, ic.x2)
        local xmax = math.max(ic.x1, ic.x2)
        local ymin = math.min(ic.y1, ic.y2)
        local ymax = math.max(ic.y1, ic.y2)
        local icw = ic:width()
        local ich = ic:height()

        local image_content_bb = BoundingBox()
        image_content_bb.x1, image_content_bb.x2 = scan_x(max_y + 1, ic.x1, ic.x2)
        image_content_bb.y1, image_content_bb.y2 = scan_y(max_x + 1, ic.y1, ic.y2)

        self.frame.bb.x1, self.frame.bb.y1 = self:image_to_local(image_content_bb.x1, image_content_bb.y1)
        self.frame.bb.x2, self.frame.bb.y2 = self:image_to_local(image_content_bb.x2, image_content_bb.y2)

        local csx = lc:width() / ic:width()
        local csy = lc:height() / ic:height()
        self._draw_args = {
            { love.graphics.newQuad(1,         2,         ic.x1,         ic.y1,         self._image), 0,     0,     0, 1,   1   },
            { love.graphics.newQuad(ic.x1,     2,         icw,           ic.y1,         self._image), lc.x1, 0,     0, csx, 1   },
            { love.graphics.newQuad(ic.x2 + 1, 2,         max_x - ic.x2, ic.y1,         self._image), lc.x2, 0,     0, 1,   1   },
            { love.graphics.newQuad(1,         ic.y1 + 1, ic.x1,         ich,           self._image), 0,     lc.y1, 0, 1,   csy },
            { love.graphics.newQuad(ic.x1,     ic.y1 + 1, icw,           ich,           self._image), lc.x1, lc.y1, 0, csx, csy },
            { love.graphics.newQuad(ic.x2 + 1, ic.y1 + 1, max_x - ic.x2, ich,           self._image), lc.x2, lc.y1, 0, 1,   csy },
            { love.graphics.newQuad(1,         ic.y2 + 2, ic.x1,         max_y - ic.y2, self._image), 0,     lc.y2, 0, 1,   1   },
            { love.graphics.newQuad(ic.x1,     ic.y2 + 2, icw,           max_y - ic.y2, self._image), lc.x1, lc.y2, 0, csx, 1   },
            { love.graphics.newQuad(ic.x2 + 1, ic.y2 + 2, max_x - ic.x2, max_y - ic.y2, self._image), lc.x2, lc.y2, 0, 1,   1   },
        }
    else
        self._image_center_bb:reset()
        self._local_center_bb:reset()
        self._draw_args = {}
        self.frame.bb:reset(0, 0, self.bb:width(). self.bb:height())
    end
end


function NinePatch:image_to_local(x, y)
    local lx, ly
    local ic = self._image_center_bb
    local lc = self._local_center_bb
    if x <= ic.x1 then
        lx = lc.x1 + x - ic.x1
    elseif x < ic.x2 then
        lx = lc.x1 + (x - ic.x1) * (lc:width() / ic:width())
    else
        lx = lc.x2 + x - ic.x2
    end
    if y <= ic.y1 then
        ly = lc.y1 + y - ic.y1
    elseif y < ic.y2 then
        ly = lc.y1 + (y - ic.y1) * (lc:height() / ic:height())
    else
        ly = lc.y2 + y - ic.y2
    end
    return lx, ly
end

function NinePatch:local_to_image(x, y)
    local ix, iy
    local ic = self._image_center_bb
    local lc = self._local_center_bb
    if x <= lc.x1 then
        lx = ic.x1 + x - lc.x1
    elseif x < lc.x2 then
        lx = ic.x1 + (x - lc.x1) * (ic:width() / lc:width())
    else
        lx = ic.x2 + x - lc.x2
    end
    if y <= lc.y1 then
        ly = ic.y1 + y - lc.y1
    elseif y < lc.y2 then
        ly = ic.y1 + (y - lc.y1) * (ic:height() / lc:height())
    else
        ly = ic.y2 + y - lc.y2
    end
    return lx, ly
end

function NinePatch:draw_image()
    if self._image ~= nil then
        for _, args in ipairs(self._draw_args) do
            love.graphics.draw(self._image, unpack(args))
        end
    end
end

function NinePatch:contains(x, y)
    if self.pixel_hit_detection == false or self.image == nil then
        -- If we have no image data, fallback to default.
        return Element.contains(self, x, y)
    end

    if not Element.contains(self, x, y) then
        -- Start with a quick bounds check.
        return false
    end

    -- Return false if pixel is transparent.
    local pixel_x, pixel_y = self:local_to_image(x, y)

    if pixel_x < 1 or pixel_x > (self.image:getWidth() - 2) or pixel_y < 1 or pixel_y > (self.image:getHeight() - 2) then
        -- return false if pixel in margin area of image.
        return false
    end

    local _, _, _, alpha = self.image:getPixel(pixel_x, pixel_y)
    return alpha > 0
end