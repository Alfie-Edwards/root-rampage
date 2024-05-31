
HackingState = {}
setup_class(HackingState, FixedPropertyTable)

function HackingState:__init()
    super().__init(self, {
        progress = 0,
    })
end
