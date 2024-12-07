require "systems.powerups"

PowerupsState = {}
setup_class(PowerupsState, FixedPropertyTable)

function PowerupsState:__init()
    super().__init(self, {
        t_near_taken = (POWERUPS.COOLDOWNS.coffee + POWERUPS.COOLDOWNS.bomb) / 2, -- Spawn out of phase with coffee
        t_far_taken = POWERUPS.COOLDOWNS.coffee, -- Double cooldown on first spawn.
        near_type = "bomb",
        far_type = "coffee",
    })
end
