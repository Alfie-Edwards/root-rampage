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
                view:set_content(Game.new(Game.MODE_ALL))
            end,
        }
    )
    grid:cell(2, 3):add_child(button_join)

    local button_back = ImageButton.new()
    button_back:set_properties(
        {
            image = assets:get_image("ui/button-back"),
            image_data = assets:get_image_data("ui/button-back"),
            x_align = "center",
            y_align = "center",
            x = grid:cell(1, 3).width / 2,
            y = grid:cell(1, 3).height / 2,
            click = function()
                view:set_content(MainMenu.new())
            end,
        }
    )
    grid:cell(1, 3):add_child(button_back)

    return obj
end
