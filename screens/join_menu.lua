require "engine.ui.simple_element"
require "engine.ui.image"
require "engine.ui.image_button"

JoinMenu = {}

setup_class(JoinMenu, SimpleElement)

function JoinMenu.new()
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

    local button_join = ImageButton.new()
    button_join:set_properties(
        {
            image = assets:get_image("ui/button-join"),
            image_data = assets:get_image_data("ui/button-join"),
            x_align = "center",
            y_align = "bottom",
            x = canvas:width() / 2,
            y = canvas:height() - 15,
            click = function()
                view:set_content(Game.new(Game.MODE_ALL))
            end,
        }
    )
    obj:add_child(button_join)

    local button_back = ImageButton.new()
    button_back:set_properties(
        {
            image = assets:get_image("ui/button-back"),
            image_data = assets:get_image_data("ui/button-back"),
            x_align = "left",
            y_align = "bottom",
            x = 20,
            y = canvas:height() - 15,
            click = function()
                view:set_content(MainMenu.new())
            end,
        }
    )
    obj:add_child(button_back)

    return obj
end
