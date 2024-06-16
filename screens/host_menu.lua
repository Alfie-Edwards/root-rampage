require "ui.image"
require "ui.image_button"
require "ui.text_box"
require "ui.containers.grid_box"
require "ui.containers.box"
require "networking"

HostMenu = {}

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

    local message_box = TextBox()
    message_box.x_align = "center"
    message_box.y_align = "center"
    message_box.x = grid:cell(2, 1).bb:width() / 2
    message_box.y = grid:cell(2, 1).bb:height() / 2
    message_box.width = grid:cell(2, 1).bb:width()
    message_box.height = 32
    message_box.background_color = {1, 1, 1, 1}
    message_box.color = {0, 0, 0, 1}
    message_box.font = ui_font
    message_box.content_margin = 4
    grid:cell(2, 1):add(message_box)

    local button_send = ImageButton()
    button_send.image = assets:get_image("ui/button-back")
    button_send.image_data = assets:get_image_data("ui/button-back")
    button_send.x_align = "center"
    button_send.y_align = "center"
    button_send.x = grid:cell(3, 1).bb:width() / 2
    button_send.y = grid:cell(3, 1).bb:height() / 2
    button_send.mousepressed = function()
        if self.connection ~= nil then
            self.connection:send(message_box.text)
        end
    end
    grid:cell(3, 1):add(button_send)

    local address_box = TextBox()
    address_box.x_align = "center"
    address_box.y_align = "center"
    address_box.x = grid:cell(2, 2).bb:width() / 2
    address_box.y = grid:cell(2, 2).bb:height() / 2
    address_box.width = grid:cell(2, 2).bb:width()
    address_box.height = 32
    address_box.background_color = {1, 1, 1, 1}
    address_box.color = {0, 0, 0, 1}
    address_box.font = ui_font
    address_box.content_margin = 4
    address_box.text = "localhost:6750"
    grid:cell(2, 2):add(address_box)

    local button_host = ImageButton()
    button_host.image = assets:get_image("ui/button-host")
    button_host.image_data = assets:get_image_data("ui/button-host")
    button_host.x_align = "center"
    button_host.y_align = "center"
    button_host.x = grid:cell(2, 3).bb:width() / 2
    button_host.y = grid:cell(2, 3).bb:height() / 2
    button_host.mousepressed = function()
        self.server = Server(address_box.text)
        self.server.connected:subscribe(
            function(connection)
                view:set_content(Game(Game.MODE_PLAYER, self.server, connection))
            end
        )
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
        view:set_content(MainMenu())
    end
    grid:cell(1, 3):add(button_back)
end

function HostMenu:update()
    if self.server ~= nil then
        self.server:poll()
    end
end
