require "ui.image"
require "ui.image_button"
require "ui.text_box"
require "ui.containers.grid_box"
require "ui.containers.box"
require "networking"

JoinMenu = {}

setup_class(JoinMenu, Box)

function JoinMenu:__init(address)
    super().__init(self)

    self.client = Client()
    self.client.connected:subscribe(
        function(connection)
            view:set_content(LobbyMenu(self.client, connection))
        end
    )

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

    local title = Text("Enter server address:")
    title.x_align = "center"
    title.y_align = "center"
    title.x = grid:cell(2, 1).bb:width() / 2
    title.y = grid:cell(2, 1).bb:height() / 2
    title.height = 32
    title.color = {1, 1, 1, 1}
    title.font = font24
    grid:cell(2, 1):add(title)

    local address_box = TextBox()
    address_box.x_align = "center"
    address_box.y_align = "center"
    address_box.x = grid:cell(2, 2).bb:width() / 2
    address_box.y = grid:cell(2, 2).bb:height() / 2
    address_box.width = grid:cell(2, 2).bb:width()
    address_box.height = 30
    address_box.background_color = {1, 1, 1, 1}
    address_box.color = {0, 0, 0, 1}
    address_box.font = font16
    address_box.content_margin = 6
    address_box.text = nil_coalesce(address, "localhost:6750")
    grid:cell(2, 2):add(address_box)

    local button_host = ImageButton()
    button_host.image = assets:get_image("ui/button-join")
    button_host.image_data = assets:get_image_data("ui/button-join")
    button_host.x_align = "center"
    button_host.y_align = "center"
    button_host.x = grid:cell(2, 3).bb:width() / 2
    button_host.y = grid:cell(2, 3).bb:height() / 2
    button_host.mousepressed = function()
        self.client:connect(address_box.text)
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

function JoinMenu:update()
    if self.connection ~= nil then
        self.client:poll()
    end
end
