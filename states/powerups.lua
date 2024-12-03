
PowerupsState = {}
setup_class(PowerupsState, FixedPropertyTable)

function PowerupsState:__init()
    super().__init(self, {
        t_near_taken = 30, -- Spawn 30 seconds late (half cooldown offset)
        t_far_taken = 0,
        near_type = "bomb",
        far_type = "coffee",
    })
end
