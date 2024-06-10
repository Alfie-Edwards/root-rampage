
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

function Host:poll()
    local event = self.host:check_events()
    if event == nil then
        event = self.host:service(100)
    end
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
        event = self.host:check_events()
        if event == nil then
            event = self.host:service(100)
        end
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
end

Server = {}
setup_class(Server, Host)

function Server:__init(address)
    super().__init(self, self.enet.host_create(address))
end


Client = {}
setup_class(Client, Host)

function Client:__init()
    super().__init(self, self.enet.host_create())
end

function Client:connect(address)
    self.host:connect(address)
    self:poll()
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
    self.peer = peer
    self.received = Event()
    self.sent = Event()
    self.connected = Event()
    self.disconnected = Event()
end

function Connection:send(message)
    self.peer:send(message, 0, "reliable")
    self.sent(message)
end

function Connection:get_latency_ms()
    return self.peer:round_trip_time()
end

function Connection:request_disconnect()
    self.peer:disconnect()
end
