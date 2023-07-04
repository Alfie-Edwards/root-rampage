require "ui.simple_element"
require "ui.image"
require "ui.image_button"

HostMenu = {}

setup_class(HostMenu, SimpleElement)

function HostMenu.new()
    local obj = magic_new()

    obj:set_properties(
        {
            width = canvas:width(),
            height = canvas:height(),
        }
    )

    local bg = Image.new()
    bg:set_properties(
        {
            image = assets:get_image("map3"),
            width = canvas:width(),
            height = canvas:height(),
        }
    )
    obj:add_child(bg)

    local button_host = ImageButton.new()
    button_host:set_properties(
        {
            image = assets:get_image("ui/button-host"),
            image_data = assets:get_image_data("ui/button-host"),
            x_align = "center",
            y_align = "bottom",
            x = canvas:width() / 2,
            y = canvas:height() - 15,
            click = function()
                view:set_content(Game.new(Game.MODE_ALL))
            end,
        }
    )
    obj:add_child(button_host)

    local button_back = ImageButton.new()
    button_back:set_properties(
        {
            image = assets:get_image("ui/button-back"),
            image_data = assets:get_image_data("ui/button-back"),
            x_align = "left",
            y_align = "bottom",
            x = 15,
            y = canvas:height() - 15,
            click = function()
                view:set_content(MainMenu.new())
            end,
        }
    )
    obj:add_child(button_back)

    return obj
end
