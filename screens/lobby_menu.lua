require "ui.image"
require "ui.image_button"
require "ui.text_box"
require "ui.containers.grid_box"
require "ui.containers.box"
require "networking"

LobbyMenu = {}

setup_class(LobbyMenu, Box)

function LobbyMenu:__init(server)
    super().__init(self)
    self.server = server
    self.server.connected:subscribe(
        function(connection)
            view:set_content(Game(Game.MODE_PLAYER, self.server, connection))
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

    local title = Text("Hosting on "..server:get_address())
    title.x_align = "center"
    title.y_align = "center"
    title.x = grid:cell(2, 1).bb:width() / 2
    title.y = grid:cell(2, 1).bb:height() / 2
    title.height = 32
    title.color = {1, 1, 1, 1}
    title.font = font24
    grid:cell(2, 1):add(title)

    local wait_text = Text("waiting for connections...")
    wait_text.x_align = "center"
    wait_text.y_align = "center"
    wait_text.x = grid:cell(2, 2).bb:width() / 2
    wait_text.y = grid:cell(2, 2).bb:height() / 2
    wait_text.height = 32
    wait_text.color = {1, 1, 1, 1}
    wait_text.font = font16
    grid:cell(2, 2):add(wait_text)

    local button_back = ImageButton()
    button_back.image = assets:get_image("ui/button-back")
    button_back.image_data = assets:get_image_data("ui/button-back")
    button_back.x_align = "center"
    button_back.y_align = "center"
    button_back.x = grid:cell(1, 3).bb:width() / 2
    button_back.y = grid:cell(1, 3).bb:height() / 2
    button_back.mousepressed = function()
        self.server:destroy()
        view:set_content(HostMenu())
    end
    grid:cell(1, 3):add(button_back)
end

function LobbyMenu:update()
    if self.server ~= nil then
        self.server:poll()
    end
end
