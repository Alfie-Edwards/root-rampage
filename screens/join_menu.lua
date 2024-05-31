require "ui.image"
require "ui.image_button"
require "ui.containers.grid_box"
require "ui.containers.box"

JoinMenu = {}

setup_class(JoinMenu, Box)

function JoinMenu:__init()
    super().__init(self)

    local bg = Image()
    bg.image = assets:get_image("map3")
    bg.width = canvas:width()
    bg.height = canvas:height()
    self:add(bg)

    local grid = GridBox()
    grid.cols = 3
    grid.rows = 3
    grid.width = canvas:width()
    grid.height = canvas:height()
    self:add(grid)

    local button_join = ImageButton()
    button_join.image = assets:get_image("ui/button-join")
    button_join.image_data = assets:get_image_data("ui/button-join")
    button_join.x_align = "center"
    button_join.y_align = "center"
    button_join.x = grid:cell(2, 3).bb:width() / 22
    button_join.y = grid:cell(2, 3).bb:height() / 2
    button_join.mousepressed = function()
        view:set_content(Game(Game.MODE_ALL))
    end
    grid:cell(2, 3):add(button_join)

    local button_back = ImageButton()
    button_back.image = assets:get_image("ui/button-back")
    button_back.image_data = assets:get_image_data("ui/button-back")
    button_back.x_align = "center"
    button_back.y_align = "center"
    button_back.x = grid:cell(1, 3).bb:width() / 2
    button_back.y = grid:cell(1, 3).bb:height() / 2
    button_back.mousepressed = function()
        view:set_content(MainMenu())
    end
    grid:cell(1, 3):add(button_back)
end
