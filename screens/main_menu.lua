require "engine.ui.simple_element"
require "engine.ui.image"
require "engine.ui.image_button"
require "engine.ui.table"
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

    local grid = Table.new()
    grid:set_properties(
        {
            cols = 3,
            rows = 3,
            width = canvas:width(),
            height = canvas:height(),
        }
    )
    obj:add_child(grid)

    local button_local = ImageButton.new()
    button_local:set_properties(
        {
            image = assets:get_image("ui/button-local"),
            image_data = assets:get_image_data("ui/button-local"),
            x_align = "center",
            y_align = "center",
            x = grid:cell(2, 1).width / 2,
            y = grid:cell(2, 1).height / 2,
            click = function()
                view:set_content(Game.new(Game.MODE_ALL))
            end,
        }
    )
    grid:cell(2, 1):add_child(button_local)

    local button_host = ImageButton.new()
    button_host:set_properties(
        {
            image = assets:get_image("ui/button-host"),
            image_data = assets:get_image_data("ui/button-host"),
            x_align = "center",
            y_align = "center",
            x = grid:cell(2, 2).width / 2,
            y = grid:cell(2, 2).height / 2,
            click = function()
                view:set_content(HostMenu.new())
            end,
        }
    )
    grid:cell(2, 2):add_child(button_host)

    local button_join = ImageButton.new()
    button_join:set_properties(
        {
            image = assets:get_image("ui/button-join"),
            image_data = assets:get_image_data("ui/button-join"),
            x_align = "center",
            y_align = "center",
            x = grid:cell(2, 3).width / 2,
            y = grid:cell(2, 3).height / 2,
            click = function()
                view:set_content(JoinMenu.new())
            end,
        }
    )
    grid:cell(2, 3):add_child(button_join)

    return obj
end
