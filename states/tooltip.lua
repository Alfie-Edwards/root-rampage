
TooltipState = {}
setup_class(TooltipState, FixedPropertyTable)

function TooltipState:__init()
    super().__init(self, {
        timer = NONE,
        duration = 1,
        message = NONE,
    })
end
