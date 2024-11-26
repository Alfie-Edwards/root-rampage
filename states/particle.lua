
ParticleState = {}
setup_class(ParticleState, FixedPropertyTable)

function ParticleState:__init(kind, t0, x, y, vx, vy, duration)
    assert(kind ~= nil)
    assert(t0 ~= nil)
    assert(x ~= nil)
    assert(y ~= nil)
    assert(vx ~= nil)
    assert(vy ~= nil)
    assert(vy ~= nil)
    super().__init(self, {
        kind = kind,
        t0 = t0,
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        duration = nil_coalesce(duration, NONE)
    })
end
