require "ui.image"
require "ui.image_button"
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
    port_box.height = 30
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

    local button_host = ImageButton()
    button_host.image = assets:get_image("ui/button-host")
    button_host.image_data = assets:get_image_data("ui/button-host")
    button_host.x_align = "center"
    button_host.y_align = "center"
    button_host.x = grid:cell(2, 3).bb:width() / 2
    button_host.y = grid:cell(2, 3).bb:height() / 2
    button_host.mousepressed = function()
        local server = Server("0.0.0.0:"..port_box.text)
        if server.errored then
            self.error.text = server.error
        else
            self.error.text = nil
            HostMenu.PORT = port_box.text
            view:set_content(LobbyMenu(server))
        end
    end
    grid:cell(2, 3):add(button_host)

    local button_back = ImageButton()
    button_back.image = assets:get_image("ui/button-back")
    button_back.image_data = assets:get_image_data("ui/button-back")
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
