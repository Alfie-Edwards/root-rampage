require "ui.image"
require "ui.containers.effect_frame"
require "ui.text_box"
require "ui.containers.grid_box"
require "ui.containers.box"
require "networking"

JoinMenu = {
    ADDRESS = "localhost:25565"
}

setup_class(JoinMenu, Box)

function JoinMenu:__init()
    super().__init(self)

    self.client = Client()
    self.client.connected:subscribe(
        function(connection)
            view:set_content(LobbyMenu(self.client, connection))
        end
    )

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
    address_box.height = 28
    address_box.background_color = {1, 1, 1, 1}
    address_box.color = {0, 0, 0, 1}
    address_box.font = font16
    address_box.content_margin = 6
    address_box.text = JoinMenu.ADDRESS
    grid:cell(2, 2):add(address_box)

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
        JoinMenu.ADDRESS = address_box.text
        self.client:connect(address_box.text)
    end
    grid:cell(2, 3):add(button_join)

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
        JoinMenu.ADDRESS = address_box.text
        view:set_content(MainMenu())
    end
    grid:cell(1, 3):add(button_back)
end

function JoinMenu:update()
    if self.connection ~= nil then
        self.client:poll()
    end
end
