require "ui.image"
require "ui.image_button"
require "ui.containers.grid_box"
require "ui.containers.box"
require "screens.host_menu"
require "screens.join_menu"
require "screens.game"

MainMenu = {}

setup_class(MainMenu, Box)

function MainMenu:__init()
    super().__init(self)

    self.background_color = {1, 0, 0, 1}

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

    local button_local = ImageButton()
    button_local.image = assets:get_image("ui/button-local")
    button_local.image_data = assets:get_image_data("ui/button-local")
    button_local.x_align = "center"
    button_local.y_align = "center"
    button_local.x = grid:cell(2, 1).bb:width() / 2
    button_local.y = grid:cell(2, 1).bb:height() / 2
    button_local.mousepressed = function()
        view:set_content(Game(Game.MODE_ALL))
    end
    grid:cell(2, 1):add(button_local)

    local button_host = ImageButton()
    button_host.image = assets:get_image("ui/button-host")
    button_host.image_data = assets:get_image_data("ui/button-host")
    button_host.x_align = "center"
    button_host.y_align = "center"
    button_host.x = grid:cell(2, 2).bb:width() / 2
    button_host.y = grid:cell(2, 2).bb:height() / 2
    button_host.mousepressed = function()
        view:set_content(HostMenu())
    end
    grid:cell(2, 2):add(button_host)

    local button_join = ImageButton()
    button_join.image = assets:get_image("ui/button-join")
    button_join.image_data = assets:get_image_data("ui/button-join")
    button_join.x_align = "center"
    button_join.y_align = "center"
    button_join.x = grid:cell(2, 3).bb:width() / 2
    button_join.y = grid:cell(2, 3).bb:height() / 2
    button_join.mousepressed = function()
        view:set_content(JoinMenu())
    end
    grid:cell(2, 3):add(button_join)
end
