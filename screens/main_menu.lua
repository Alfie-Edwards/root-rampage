require "ui.simple_element"
require "ui.image"
require "ui.image_button"
require "screens.host_menu"
require "screens.join_menu"
require "screens.game"

MainMenu = {}

setup_class(MainMenu, SimpleElement)

function MainMenu.new()
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

    local button_local = ImageButton.new()
    button_local:set_properties(
        {
            image = assets:get_image("ui/button-local"),
            image_data = assets:get_image_data("ui/button-local"),
            x_align = "center",
            y_align = "top",
            x = canvas:width() / 2,
            y = 15,
            click = function()
                view:set_content(Game.new(Game.MODE_ALL))
            end,
        }
    )
    obj:add_child(button_local)

    local button_host = ImageButton.new()
    button_host:set_properties(
        {
            image = assets:get_image("ui/button-host"),
            image_data = assets:get_image_data("ui/button-host"),
            x_align = "center",
            y_align = "center",
            x = canvas:width() / 2,
            y = canvas:height() / 2,
            click = function()
                view:set_content(HostMenu.new())
            end,
        }
    )
    obj:add_child(button_host)

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
                view:set_content(JoinMenu.new())
            end,
        }
    )
    obj:add_child(button_join)

    return obj
end
