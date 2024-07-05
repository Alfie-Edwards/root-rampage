effects = {}

function effects.highlight(amount)
    amount = nil_coalesce(amount, 0.15)
    local shader = assets:get_shader("ui/highlight")
    return function(e)
        shader:send("amount", amount)
        love.graphics.setShader(shader)
        e:draw()
        love.graphics.setShader()
    end
end

function effects.dim(amount)
    amount = nil_coalesce(amount, 0.15)
    local shader = assets:get_shader("ui/highlight")
    return function(e)
        shader:send("amount", -amount)
        love.graphics.setShader(shader)
        e:draw()
        love.graphics.setShader()
    end
end
