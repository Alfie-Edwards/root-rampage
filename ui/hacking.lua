require "ui.element"
require "ui.image"
require "ui.image_button"

Hacking = {
    MAX_POINTS = 3,

    POINTS_INSET_X = 20,
    POINTS_INSET_Y = 20,

    POINT_ICON_SIZE_SCALE = 2,
    POINT_ICON_SPACING = 2,
    POINT_ICON_INSET_Y = 4,

    door_open_icon_offset_x = nil,

    state = nil,

    points = nil,
    door_button_map = {},
    point_icons = {},
}
setup_class(Hacking, Element)

function Hacking:__init(state)
    super().__init(self)

    self.state = state

    self.points = Hacking.MAX_POINTS

    local close_img = assets:get_image("ui/HackDoor1Closed")
    self.door_open_icon_offset_x = close_img:getWidth()

    -- icons over each door
    state:foreach("Door",
        function(door)
            local button_positions = self:door_button_positions(door)

            -- 'close' icon
            local close_door_button = ImageButton()
            close_door_button:set({
                image = close_img,
                image_data = assets:get_image_data("ui/HackDoor1Closed"),
                x_align = "left",
                y_align = "bottom",
                x = button_positions.close.x,
                y = button_positions.close.y,
                mousereleased = function()
                    if door.is_locked and
                       not door.is_open and
                       not door:is_transitioning() then
                        self:unlock_door(door)
                    else
                        self:lock_door_closed(door)
                    end
                end,
            })
            self:_add_visual_child(close_door_button)

            -- 'open' icon
            local open_door_button = ImageButton()
            open_door_button:set({
                image = assets:get_image("ui/HackDoor1Open"),
                image_data = assets:get_image_data("ui/HackDoor1Open"),
                x_align = "left",
                y_align = "bottom",
                x = button_positions.open.x,
                y = button_positions.open.y,
                mousereleased = function()
                    if door.is_locked and
                       door.is_open and
                       not door:is_transitioning() then
                        self:unlock_door(door)
                    else
                        self:lock_door_open(door)
                    end
                end,
            })
            self:_add_visual_child(open_door_button)

            self.door_button_map[door] = {
                open = open_door_button,
                close = close_door_button,
            }
        end
    )

    -- points background banner
    local points_bg = Image()
    local points_bg_img = assets:get_image("ui/HackBG")
    local points_bg_width = points_bg_img:getWidth() * Hacking.POINT_ICON_SIZE_SCALE
    local points_bg_aspect = points_bg_img:getHeight() / points_bg_img:getWidth()
    points_bg:set({
        image = points_bg_img,
        image_data = assets:get_image_data("ui/HackBG"),
        x_align = "left",
        y_align = "top",
        x = Hacking.POINTS_INSET_X,
        y = Hacking.POINTS_INSET_Y,
        width = points_bg_width,
        height = points_bg_width * points_bg_aspect,
    })
    self:_add_visual_child(points_bg)

    -- individual point icons
    local point_img = assets:get_image("ui/Hack1")
    local point_img_width = point_img:getWidth() * Hacking.POINT_ICON_SIZE_SCALE
    local point_img_aspect = point_img:getHeight() / point_img:getWidth()
    -- horizontally centre the list of points over the background image
    local total_points_width = point_img_width * Hacking.MAX_POINTS +
                               Hacking.POINT_ICON_SPACING * (Hacking.MAX_POINTS - 1)
    local centring_adjustment = Hacking.POINTS_INSET_X +
                                (points_bg_width / 2) -
                                (total_points_width / 2)

    for i=1,Hacking.MAX_POINTS do
        local point_icon = Image()
        point_icon:set({
            image = img,
            image_data = assets:get_image_data("ui/Hack1"),
            x_align = "left",
            y_align = "top",
            x = centring_adjustment + (i - 1) * (point_img_width + Hacking.POINT_ICON_SPACING),
            y = Hacking.POINTS_INSET_Y + Hacking.POINT_ICON_INSET_Y,
            width = point_img_width,
            height = point_img_width * point_img_aspect,
        })
        self:_add_visual_child(point_icon)

        table.insert(self.point_icons, point_icon)
    end
end

function Hacking:use_point()
    if self.points == 0 then
        return false
    end

    self.point_icons[self.points]:set({
        image = assets:get_image("ui/Hack2"),
        image_data = assets:get_image_data("ui/Hack2"),
    })

    self.points = self.points - 1

    return true
end

function Hacking:restore_point()
    self.points = math.min(self.points + 1, Hacking.MAX_POINTS)

    self.point_icons[self.points]:set({
        image = assets:get_image("ui/Hack1"),
        image_data = assets:get_image_data("ui/Hack1"),
    })

end

function Hacking:lock_door_open(door)
    if door:is_transitioning() then
        return
    end

    if door.is_locked and not door.is_open then
        door:lock_open()
        return
    end

    if self:use_point() then
        if not door:lock_open() then
            self:restore_point()
        end
    end
end

function Hacking:lock_door_closed(door)
    if door:is_transitioning() then
        return
    end

    if door.is_locked and door.is_open then
        door:lock_closed()
        return
    end

    if self:use_point() then
        if door:lock_closed() then
            self:restore_point()
        end
    end
end

function Hacking:unlock_door(door)
    door:unlock()
    self:restore_point()
end

function Hacking:door_button_positions(door)
    local pos = door:pixel_pos(self.state)
    local camera = self.state:first("Camera")
    if camera then
        pos.x = pos.x - camera.x
        pos.y = pos.y - camera.y
    end

    return {
        close = {
            x = pos.x,
            y = pos.y,
        },
        open = {
            x = pos.x + self.door_open_icon_offset_x,
            y = pos.y,
        },
    }
end

function Hacking:update(dt)
    for door, buttons in pairs(self.door_button_map) do
        local button_positions = self:door_button_positions(door)

        buttons.close:set({
            x = button_positions.close.x,
            y = button_positions.close.y,
        })

        buttons.open:set({
            x = button_positions.open.x,
            y = button_positions.open.y,
        })
    end
end

function Hacking:draw()
    for door, buttons in pairs(self.door_button_map) do
        -- draw highlights against 'active' buttons
        if door.is_locked then
            love.graphics.setColor({1, 1, 0, 1})
            if door.is_open then
                local icon_width = buttons.open.image:getWidth()
                local hl_rad = (icon_width + 5) / 2
                love.graphics.circle(
                    "fill",
                    buttons.open.x + 0.75 * hl_rad,
                    (buttons.open.y - icon_width) + 0.75 * hl_rad,
                    hl_rad)
            else
                local icon_width = buttons.close.image:getWidth()
                local hl_rad = (icon_width + 5) / 2
                love.graphics.circle(
                    "fill",
                    buttons.close.x + 0.75 * hl_rad,
                    (buttons.close.y - icon_width) + 0.75 * hl_rad,
                    hl_rad)
            end
        end
    end

    super().draw(self)
end
