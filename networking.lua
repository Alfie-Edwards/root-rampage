Host = {
    host = nil,
    connections = nil,
    connected = nil, -- connected(connection)
    disconnected = nil, -- disconnected(connection)
    enet = require "enet",
}
setup_class(Host)

function Host:__init(host)
    super().__init(self)
    self.host = host
    self.connections = {}
    self.connected = Event()
    self.disconnected = Event()
end

function Host:flush()
    pcall(function()
        self.host:flush()
    end)
end

function Host:poll(timeout_ms)
    pcall(function()
        local timeout_ms = nil_coalesce(timeout_ms, 0)
        local event = self.host:service(timeout_ms)
        while event ~= nil do
            if event.type == "receive" then
                local connection = self.connections[event.peer:connect_id()]
                connection.received(event.data)
            elseif event.type == "disconnect" then
                local connection = self.connections[event.peer:connect_id()]
                if connection ~= nil then
                    self.connections[event.peer] = nil
                    connection:request_disconnect()
                    self.disconnected(connection)
                    connection:disconnected()
                    connection.connected:unsubscribe_all()
                    connection.disconnected:unsubscribe_all()
                    connection.sent:unsubscribe_all()
                    connection.received:unsubscribe_all()
                end
            elseif event.type == "connect" then
                local connection = Connection(event.peer)
                local id = event.peer:connect_id()
                self.connections[id] = connection
                self.connected(self.connections[id])
                self.connections[id].connected()
            end
           event = self.host:service(timeout_ms)
        end
        local dead = {}
        for id, connection in pairs(self.connections) do
            if connection.peer:state() == "disconnected" then
                self.disconnected(connection)
                connection:disconnected()
                connection.connected:unsubscribe_all()
                connection.disconnected:unsubscribe_all()
                connection.sent:unsubscribe_all()
                connection.received:unsubscribe_all()
                table.insert(dead, id)
            end
        end
        for _, id in ipairs(dead) do
            self.connections[id] = nil
        end
    end)
end

function Host:destroy()
    pcall(function()
        for _, connection in pairs(self.connections) do
            connection:request_disconnect()
        end
        self.host:flush()
        self.host:destroy()
    end)
end

Server = {}
setup_class(Server, Host)

function Server:__init(address)
    local host, success
    success, self.error = pcall(function() host = self.enet.host_create(address, 1) end)
    self.errored = not success
    if success and host == nil then
        self.errored = true
        self.error = "host_create returned nil"
    end
    super().__init(self, host)
end

function Server:get_address()
    local result, success
    success, self.error = pcall(function() result = self.host:get_socket_address() end)
    self.errored = not success
    return result
end


Client = {}
setup_class(Client, Host)

function Client:__init()
    super().__init(self, self.enet.host_create())
end

function Client:connect(address)
    pcall(function()
        self.host:connect(address)
        self:poll()
    end)
end


Connection = {
    peer = nil,
    received = nil, -- received(message)
    sent = nil, -- sent(message)
    connected = nil, -- connected()
    disconnected = nil, -- disconnected()
}
setup_class(Connection)

function Connection:__init(peer)
    super().__init(self)
    peer:last_round_trip_time(30) -- Initial guess.
    self.peer = peer
    self.received = Event()
    self.sent = Event()
    self.connected = Event()
    self.disconnected = Event()
end

function Connection:send(message)
    pcall(function()
        self.peer:send(message, 0, "reliable")
        self.sent(message)
    end)
end

function Connection:get_latency_ms()
    local result = -1
    pcall(function() result = self.peer:round_trip_time() end)
    return result
end

function Connection:get_latency_s()
    return self:get_latency_ms() / 1000
end

function Connection:request_disconnect()
    pcall(function() self.peer:disconnect() end)
end

function Connection:get_state()
    local result = "error"
    pcall(function() result = self.peer:state() end)
    return result
end
