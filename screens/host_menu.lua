require "ui.image"
require "ui.containers.effect_frame"
require "ui.text_box"
require "ui.containers.grid_box"
require "ui.containers.box"
require "screens.lobby_menu"
require "networking"

HostMenu = {
    PORT = "25565"
}

setup_class(HostMenu, Box)

function HostMenu:__init()
    super().__init(self)

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

    local title = Text("Enter port:")
    title.x_align = "center"
    title.y_align = "center"
    title.x = grid:cell(2, 1).bb:width() / 2
    title.y = grid:cell(2, 1).bb:height() / 2
    title.height = 32
    title.color = {1, 1, 1, 1}
    title.font = font24
    grid:cell(2, 1):add(title)

    local port_box = TextBox()
    port_box.x_align = "center"
    port_box.y_align = "center"
    port_box.x = grid:cell(2, 2).bb:width() / 2
    port_box.y = grid:cell(2, 2).bb:height() / 2
    port_box.width = grid:cell(2, 2).bb:width() / 2.5
    port_box.height = 28
    port_box.text_align = "center"
    port_box.background_color = {1, 1, 1, 1}
    port_box.color = {0, 0, 0, 1}
    port_box.font = font16
    port_box.content_margin = 6
    port_box.text = HostMenu.PORT
    grid:cell(2, 2):add(port_box)

    self.error = Text()
    self.error.x_align = "center"
    self.error.y_align = "bottom"
    self.error.text_align = "center"
    self.error.x = grid:cell(2, 2).bb:width() / 2
    self.error.y = grid:cell(2, 2).bb:height()
    self.error.height = 48
    self.error.color = {1, 0.3, 0.3, 1}
    self.error.font = font16
    grid:cell(2, 2):add(self.error)

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
    button_host.x = grid:cell(2, 3).bb:width() / 2
    button_host.y = grid:cell(2, 3).bb:height() / 2
    button_host.clip = false
    button_host.mousepressed = function()
        local server = Server("0.0.0.0:"..port_box.text)
        if server.errored then
            self.error.text = server.error
        else
            self.error.text = nil
            HostMenu.PORT = port_box.text
            if server:get_address() ~= nil then
                view:set_content(LobbyMenu(server))
            else
                self.error.text = server.error
            end
        end
    end
    grid:cell(2, 3):add(button_host)

    local button_back = EffectFrame(
        NinePatch(
            assets:get_image_data("ui/button.9"),
            Text("BACK", font16, rgba(82, 65, 51))
        )
    )
    button_back.content.width = 108
    button_back.content.height = 64
    button_back.width = button_back.content.width
    button_back.height = button_back.content.height
    button_back.content.content.x = button_back.content.frame.bb:width() / 2
    button_back.content.content.y = button_back.content.frame.bb:height() / 2
    button_back.content.content.x_align = "center"
    button_back.content.content.y_align = "center"
    button_back.x_align = "center"
    button_back.y_align = "center"
    button_back.x = grid:cell(1, 3).bb:width() / 2
    button_back.y = grid:cell(1, 3).bb:height() / 2
    button_back.mousepressed = function()
        HostMenu.PORT = port_box.text
        view:set_content(MainMenu())
    end
    grid:cell(1, 3):add(button_back)
end
