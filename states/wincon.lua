
WinconState = {}
setup_class(WinconState, FixedPropertyTable)

function WinconState:__init()
    super().__init(self, {
        game_over = false,
        end_screen = NONE,
    })
end
