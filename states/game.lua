require "states.branch"
require "states.door"
require "states.hacking"
require "states.node"
require "states.player"
require "states.powerups"
require "states.roots"
require "states.terminal"
require "states.tooltip"
require "states.tree_spot"
require "states.wincon"
require "systems.level"
require "systems.terminal"
require "systems.tree_spot"

GameState = {}
setup_class(GameState, FixedPropertyTable)

function GameState:__init()
    local cs = LEVEL.cell_size()

    local terminals = PropertyTable()
    for i, pos in ipairs(TERMINAL.POSITIONS) do
        terminals[i] = TerminalState(pos.x * cs, pos.y * cs)
    end

    local tree_spots = PropertyTable()
    for i, pos in ipairs(TREE_SPOT.POSITIONS) do
        tree_spots[i] = TreeSpotState(pos.x * cs, pos.y * cs)
    end

    super().__init(self, {
        newest_node = NONE,
        branches = PropertyTable(),
        nodes = RStar({M = 8, m=4, reinsert_p=4, reinsert_method='weighted'}),
        terminals = terminals,
        tree_spots = tree_spots,

        door = DoorState(cs, 0),
        hacking = HackingState(),
        player = PlayerState(cs),
        powerups = PowerupsState(),
        roots = RootsState(),
        tooltip = TooltipState(),
        wincon = WinconState(),
        t = 0,
        dt = 1/30,
    })

    TREE_SPOT.create_node(tree_spots[1], nil, self)
end
