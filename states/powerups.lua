
PowerupsState = {}
setup_class(PowerupsState, FixedPropertyTable)

function PowerupsState:__init()
    super().__init(self, {
        t_near_taken = -34,
        t_far_taken = 0,
        near_type = "coffee",
        far_type = "coffee",
        coffee_spawned = 0
    })
end
