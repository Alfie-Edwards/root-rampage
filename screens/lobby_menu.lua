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
