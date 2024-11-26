require "ui.image"
require "ui.containers.effect_frame"
require "ui.text_box"
require "ui.containers.grid_box"
require "ui.containers.box"
require "networking"

LobbyMenu = {}

setup_class(LobbyMenu, Box)

function LobbyMenu:__init(host, connection)
    super().__init(self)
    self.host = host
    self.connection = connection
    self.is_remote = is_type(host, Client)
    self.you_ready = false
    self.opponent_ready = false
    self.swapped = false

    -- Dynamically generate to capture self.
    self.on_disconnected = function()
        if self.is_remote then
            self:unsubscribe()
            self.host:destroy()
            view:set_content(JoinMenu())
        else
            self:unsubscribe_connection()
            self.connection = nil
            self:set_you_to_unready()
            self:set_opponent_to_unready()
            self.grid:cell(2, 3):clear()
            self.grid:cell(2, 4):clear()
            self.grid:cell(2, 5):clear()
            self.grid:cell(3, 4):clear()
            self.grid:cell(4, 3):clear()
            self.grid:cell(4, 4):clear()
            self.grid:cell(4, 5):clear()
        end
    end
    self.on_received = function(message)
        if message == "start" then
            self:start()
        elseif message == "ready" then
            self:set_opponent_to_ready()
        elseif message == "unready" then
            self:set_opponent_to_unready()
        elseif message == "swap" then
            self:swap(true)
        end
    end
    self.on_host_connected = function(connection)
        self:unsubscribe_connection()
        self.connection = nil
        if self.swapped then
            self:swap(true)
        end
        if self.you_ready then
            self:set_you_to_unready()
        end
        self.connection = connection
        self:subscribe_connection()
        self.grid:cell(2, 3):add(self.you_text)
        self.grid:cell(2, 4):add(self.you_role_text)
        self.grid:cell(2, 5):add(self.button_you_ready)
        self.grid:cell(3, 4):add(self.button_swap)
        self.grid:cell(4, 3):add(self.opponent_text)
        self.grid:cell(4, 4):add(self.opponent_role_text)
        self.grid:cell(4, 5):add(self.button_opponent_ready)
    end

    self:subscribe()

    local bg = Image(assets:get_image_data("map3"))
    bg.width = canvas:width()
    bg.height = canvas:height()
    self:add(bg)

    self.grid = GridBox()
    self.grid.cols = 5
    self.grid.rows = 5
    self.grid.width = canvas:width()
    self.grid.height = canvas:height()
    self:add(self.grid)
    self.grid.col_widths = {3, 2, 1, 2, 1}
    self.grid.row_heights = {19, 19, 19, 19, 20}

    local title = Text()
    if self.is_remote then
        title.text = "Connected to lobby"
    else
        title.text = "Hosting lobby on "..host:get_address()
    end
    title.x_align = "center"
    title.y_align = "center"
    title.x = self.grid:cell(2, 1).bb:width() * 0.75
    title.y = self.grid:cell(2, 1).bb:height() / 2
    title.height = 32
    title.color = {1, 1, 1, 1}
    title.font = font24
    self.grid:cell(2, 1):add(title)

    self.status = Text()
    self.status.x_align = "center"
    self.status.y_align = "center"
    self.status.x = self.grid:cell(2, 2).bb:width() * 0.75
    self.status.text_align = "center"
    self.status.height = 48
    self.status.color = {1, 1, 1, 1}
    self.status.font = font16
    self.grid:cell(2, 2):add(self.status)

    self.you_text = Text("You")
    self.you_text.x_align = "center"
    self.you_text.y_align = "center"
    self.you_text.text_align = "center"
    self.you_text.x = self.grid:cell(2, 3).bb:width() / 2
    self.you_text.height = 48
    self.you_text.color = {1, 1, 1, 1}
    self.you_text.font = font24

    self.opponent_text = Text("Opponent")
    self.opponent_text.x_align = "center"
    self.opponent_text.y_align = "center"
    self.opponent_text.text_align = "center"
    self.opponent_text.x = self.grid:cell(4, 3).bb:width() / 2
    self.opponent_text.height = 48
    self.opponent_text.color = {1, 1, 1, 1}
    self.opponent_text.font = font24

    self.button_swap = EffectFrame(
        NinePatch(
            assets:get_image_data("ui/button.9"),
            Text("SWAP", font16, rgba(82, 65, 51))
        )
    )
    self.button_swap.content.width = 108
    self.button_swap.content.height = 64
    self.button_swap.width = self.button_swap.content.width
    self.button_swap.height = self.button_swap.content.height
    self.button_swap.content.content.x = self.button_swap.content.frame.bb:width() / 2
    self.button_swap.content.content.y = self.button_swap.content.frame.bb:height() / 2
    self.button_swap.content.content.x_align = "center"
    self.button_swap.content.content.y_align = "center"
    self.button_swap.x_align = "center"
    self.button_swap.y_align = "center"
    self.button_swap.x = self.grid:cell(3, 4).bb:width() / 2
    self.button_swap.y = -16
    self.button_swap.mousepressed = function() self:swap(false) end

    self.you_role_text = Text()
    self.you_role_text.x_align = "center"
    self.you_role_text.y_align = "center"
    self.you_role_text.text_align = "center"
    self.you_role_text.x = self.grid:cell(2, 4).bb:width() / 2
    self.you_role_text.height = 48
    self.you_role_text.color = {1, 1, 1, 1}
    self.you_role_text.font = font16

    self.opponent_role_text = Text()
    self.opponent_role_text.x_align = "center"
    self.opponent_role_text.y_align = "center"
    self.opponent_role_text.text_align = "center"
    self.opponent_role_text.x = self.grid:cell(4, 4).bb:width() / 2
    self.opponent_role_text.height = 48
    self.opponent_role_text.color = {1, 1, 1, 1}
    self.opponent_role_text.font = font16

    self:update_role_text()

    self.button_you_ready = EffectFrame(
        NinePatch(
            assets:get_image_data("ui/button_red.9"),
            Text("NOT READY", font16, rgba(82, 65, 51))
        )
    )
    self.button_you_ready.content.width = 180
    self.button_you_ready.content.height = 85
    self.button_you_ready.width = self.button_you_ready.content.width
    self.button_you_ready.height = self.button_you_ready.content.height
    self.button_you_ready.content.content.x = self.button_you_ready.content.frame.bb:width() / 2
    self.button_you_ready.content.content.y = self.button_you_ready.content.frame.bb:height() / 2
    self.button_you_ready.content.content.x_align = "center"
    self.button_you_ready.content.content.y_align = "center"
    self.button_you_ready.x_align = "center"
    self.button_you_ready.y_align = "center"
    self.button_you_ready.x = self.grid:cell(2, 5).bb:width() / 2
    self.button_you_ready.mousepressed = function() self:toggle_ready() end

    self.button_opponent_ready = EffectFrame(
        NinePatch(
            assets:get_image_data("ui/button_red.9"),
            Text("NOT READY", font16, rgba(82, 65, 51))
        )
    )
    self.button_opponent_ready.content.width = 180
    self.button_opponent_ready.content.height = 85
    self.button_opponent_ready.width = self.button_opponent_ready.content.width
    self.button_opponent_ready.height = self.button_opponent_ready.content.height
    self.button_opponent_ready.content.content.x = self.button_opponent_ready.content.frame.bb:width() / 2
    self.button_opponent_ready.content.content.y = self.button_opponent_ready.content.frame.bb:height() / 2
    self.button_opponent_ready.content.content.x_align = "center"
    self.button_opponent_ready.content.content.y_align = "center"
    self.button_opponent_ready.x_align = "center"
    self.button_opponent_ready.y_align = "center"
    self.button_opponent_ready.x = self.grid:cell(4, 5).bb:width() / 2

    if self.connection ~= nil then
        self.grid:cell(2, 3):add(self.you_text)
        self.grid:cell(2, 4):add(self.you_role_text)
        self.grid:cell(2, 5):add(self.button_you_ready)
        self.grid:cell(3, 4):add(self.button_swap)
        self.grid:cell(4, 3):add(self.opponent_text)
        self.grid:cell(4, 4):add(self.opponent_role_text)
        self.grid:cell(4, 5):add(self.button_opponent_ready)
    end

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
    button_back.x = self.grid:cell(1, 5).bb:width() / 2
    button_back.mousepressed = function()
        self:unsubscribe()
        if self.is_remote then
            view:set_content(JoinMenu())
        else
            view:set_content(HostMenu())
        end
        self.host:destroy()
    end
    self.grid:cell(1, 5):add(button_back)
end

function LobbyMenu:subscribe_connection()
    if self.connection ~= nil then
        self.connection.disconnected:subscribe(self.on_disconnected)
        self.connection.received:subscribe(self.on_received)
    end
end

function LobbyMenu:unsubscribe_connection()
    if self.connection ~= nil then
        self.connection.disconnected:unsubscribe(self.on_disconnected)
        self.connection.received:unsubscribe(self.on_received)
    end
end

function LobbyMenu:subscribe()
    self:subscribe_connection()
    if not self.is_remote then
        self.host.connected:subscribe(self.on_host_connected)
    end
end

function LobbyMenu:unsubscribe()
    self:unsubscribe_connection()
    if not self.is_remote then
        self.host.connected:unsubscribe(self.on_host_connected)
    end
end

function LobbyMenu:send_start()
    self.connection:send("start")
    self.host:flush()
    self:start()
end

function LobbyMenu:set_you_to_ready()
    self.you_ready = true
    self.button_you_ready.content.image = assets:get_image_data("ui/button_green.9")
    self.button_you_ready.content.content.text = "READY"
    if self.connection ~= nil then
        self.connection:send("ready")
        self.host:poll()
        if self.opponent_ready then
            self:send_start()
        end
    end
end

function LobbyMenu:set_you_to_unready()
    self.you_ready = false
    self.button_you_ready.content.image = assets:get_image_data("ui/button_red.9")
    self.button_you_ready.content.content.text = "NOT READY"
    if self.connection ~= nil then
        self.connection:send("unready")
    end
end

function LobbyMenu:set_opponent_to_ready()
    self.opponent_ready = true
    self.button_opponent_ready.content.image = assets:get_image_data("ui/button_green.9")
    self.button_opponent_ready.content.content.text = "READY"
end

function LobbyMenu:set_opponent_to_unready()
    self.opponent_ready = false
    self.button_opponent_ready.content.image = assets:get_image_data("ui/button_red.9")
    self.button_opponent_ready.content.content.text = "NOT READY"
end

function LobbyMenu:toggle_ready()
    if self.you_ready then
        self:set_you_to_unready()
    else
        self:set_you_to_ready()
    end
end

function LobbyMenu:swap(from_opponent)
    self:set_you_to_unready()
    self.swapped = not self.swapped
    self:update_role_text()
    if not from_opponent and self.connection ~= nil then
        self.connection:send("swap")
    end
end

function LobbyMenu:update_role_text()
    if self.swapped == self.is_remote then
        self.you_role_text.text = "Roots"
        self.opponent_role_text.text = "Axe Man"
    else
        self.you_role_text.text = "Axe Man"
        self.opponent_role_text.text = "Roots"
    end
end

function LobbyMenu:start()
    self:unsubscribe()
    if self.swapped == self.is_remote then
        view:set_content(Game(Game.MODE_ROOTS, self.host, self.connection))
    else
        view:set_content(Game(Game.MODE_PLAYER, self.host, self.connection))
    end
end

function LobbyMenu:update()
    if self.host ~= nil then
        self.host:poll()
    end

    if self.connection == nil then
        self.status.text = "waiting for connections..."
    else
        self.status.text = "status: "..self.connection:get_state().."\n\nlatency: "..self.connection:get_latency_ms().."ms"
    end
end
