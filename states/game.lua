require "utils"
require "engine.state"
require "states.branch"
require "states.door"
require "states.hacking"
require "states.node"
require "states.player"
require "states.roots"
require "states.terminal"
require "states.tooltip"
require "states.tree_spot"
require "states.wincon"
require "systems.level"
require "systems.terminal"
require "systems.tree_spot"

GameState = {}
setup_class("GameState", State)

function GameState.new()
    local cs = LEVEL.cell_size()

    local terminals = {}
    for _, pos in ipairs(TERMINAL.POSITIONS) do
        table.insert(terminals, TerminalState.new(pos.x * cs, pos.y * cs))
    end

    local tree_spots = {}
    for _, pos in ipairs(TREE_SPOT.POSITIONS) do
        table.insert(tree_spots, TreeSpotState.new(pos.x * cs, pos.y * cs))
    end

    local obj = State.new({
        branches = {},
        nodes = {},
        terminals = terminals,
        tree_spots = tree_spots,

        door = DoorState.new(cs, 0),
        hacking = HackingState.new(),
        player = PlayerState.new(cs),
        roots = RootsState.new(),
        tooltip = TooltipState.new(),
        wincon = WinconState.new(),
        t = 0,
        dt = 1/60,
    })
    setup_instance(obj, GameState)

    TREE_SPOT.create_node(tree_spots[1], nil, obj)

    return obj
end
