require "ui.image"
require "ui.containers.nine_patch"
require "ui.containers.effect_frame"
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

    local bg = Image(assets:get_image_data("map3"))
    bg.width = canvas:width()
    bg.height = canvas:height()
    self:add(bg)

    local grid = GridBox()
    grid.cols = 3
    grid.rows = 3
    grid.width = canvas:width()
    grid.height = canvas:height()
    grid.row_heights = {2.5, 1, 2.5}
    self:add(grid)

    local button_local = EffectFrame(
        NinePatch(
            assets:get_image_data("ui/button.9"),
            Text("LOCAL", font32, rgba(82, 65, 51))
        )
    )
    button_local.content.width = 268
    button_local.content.height = 95
    button_local.width = button_local.content.width
    button_local.height = button_local.content.height
    button_local.content.content.x = button_local.content.frame.bb:width() / 2
    button_local.content.content.y = button_local.content.frame.bb:height() / 2
    button_local.content.content.x_align = "center"
    button_local.content.content.y_align = "center"
    button_local.x_align = "center"
    button_local.y_align = "center"
    button_local.x = grid:cell(2, 1).bb:width() / 2
    button_local.y = grid:cell(2, 1).bb:height() / 2
    button_local.mousepressed = function()
        view:set_content(Game(Game.MODE_ALL))
    end
    grid:cell(2, 1):add(button_local)

    local button_host = EffectFrame(
        NinePatch(
            assets:get_image_data("ui/button.9"),
            Text("HOST", font32, rgba(82, 65, 51))
        )
    )
    button_host.content.width = 268
    button_host.content.height = 95
    button_host.width = button_host.content.width
    button_host.height = button_host.content.height
    button_host.content.content.x = button_host.content.frame.bb:width() / 2
    button_host.content.content.y = button_host.content.frame.bb:height() / 2
    button_host.content.content.x_align = "center"
    button_host.content.content.y_align = "center"
    button_host.x_align = "center"
    button_host.y_align = "center"
    button_host.x = grid:cell(2, 2).bb:width() / 2
    button_host.y = grid:cell(2, 2).bb:height() / 2
    button_host.mousepressed = function()
        view:set_content(HostMenu())
    end
    grid:cell(2, 2):add(button_host)

    local button_join = EffectFrame(
        NinePatch(
            assets:get_image_data("ui/button.9"),
            Text("JOIN", font32, rgba(82, 65, 51))
        )
    )
    button_join.content.width = 268
    button_join.content.height = 95
    button_join.width = button_join.content.width
    button_join.height = button_join.content.height
    button_join.content.content.x = button_join.content.frame.bb:width() / 2
    button_join.content.content.y = button_join.content.frame.bb:height() / 2
    button_join.content.content.x_align = "center"
    button_join.content.content.y_align = "center"
    button_join.x_align = "center"
    button_join.y_align = "center"
    button_join.x = grid:cell(2, 3).bb:width() / 2
    button_join.y = grid:cell(2, 3).bb:height() / 2
    button_join.mousepressed = function()
        view:set_content(JoinMenu())
    end
    grid:cell(2, 3):add(button_join)
end
