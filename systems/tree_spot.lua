require "sprite"
require "states.tree_spot"
require "systems.node"

TREE_SPOT = {
    RADIUS = 24,
    TIME = 5,
    TOOLTIP = "Grow tree",
    TOOLTIP2 = "Taking root...",

    SPRITES = {
        patch = sprite.make("patch of soil"),
        plant = sprite.make_set("tree/", { "tree 1", "tree 2", "tree 3" }),
    },

    GROW_DURATION = 2,
    WITHER_DURATION = 1,

    POSITIONS = {
        { x = 45.5, y = 13.5 },
        { x = 35.5, y =  8.5 },
        { x = 35.5, y = 18.5 },
        { x = 15.5, y =  8.5 },
        { x = 15.5, y = 18.5 },
    },
}

function TREE_SPOT.update(state, inputs)
    for _, tree_spot in ipairs(state.tree_spots) do
        if tree_spot.node ~= nil and tree_spot.node.is_dead then
            tree_spot.node = nil
            tree_spot.t_grown = NEVER
            tree_spot.t_cut = state.t
        end

        if tree_spot.node ~= nil and tree_spot.t_grown == NEVER then
            tree_spot.t_grown = state.t
            tree_spot.t_cut = NEVER
        end

        if tree_spot.node == nil and
               state.roots.grow_node ~= nil and
               state.tooltip.message == nil and
               sq_dist(tree_spot.x, tree_spot.y, inputs.roots_pos_x, inputs.roots_pos_y) < TREE_SPOT.RADIUS ^ 2 then
            state.tooltip.message = TREE_SPOT.TOOLTIP
        end
    end
end

function TREE_SPOT.draw(state, inputs, dt)
    for _, tree_spot in ipairs(state.tree_spots) do
        TREE_SPOT.draw_patch(tree_spot)
        TREE_SPOT.draw_plant(tree_spot, state.t + dt)
    end
end

function TREE_SPOT.draw_patch(tree_spot)
    local sprite = TREE_SPOT.SPRITES.patch

    local ox = sprite:getWidth() / 2
    local oy = sprite:getHeight() / 2

    local sx = (TREE_SPOT.RADIUS * 2) / sprite:getWidth()
    local sy = (TREE_SPOT.RADIUS * 2) / sprite:getHeight()

    love.graphics.setColor({1, 1, 1, 1})
    love.graphics.draw(sprite, tree_spot.x, tree_spot.y, 0, sx, sy, ox, oy)
end

function TREE_SPOT.draw_plant(tree_spot, t)
    local sprite = TREE_SPOT.plant_sprite(tree_spot, t)
    if sprite == nil then
        return
    end

    local ox = sprite:getWidth() / 2
    local oy = sprite:getHeight() / 2

    -- want to draw the sprite slightly above centre, since the 'ground' bit is near
    -- the bottom
    oy = oy + 5

    love.graphics.setColor({1, 1, 1, 1})
    love.graphics.draw(sprite, tree_spot.x, tree_spot.y, 0, 1, 1, ox, oy)
end

function TREE_SPOT.plant_sprite(tree_spot, t)
    if tree_spot.node ~= nil and tree_spot.t_grown ~= NEVER then
        return sprite.sequence(TREE_SPOT.SPRITES.plant, TREE_SPOT.GROW_DURATION, t - tree_spot.t_grown)
    end

    if tree_spot.t_cut ~= NEVER and TREE_SPOT.since_cut(tree_spot, t) < TREE_SPOT.WITHER_DURATION then
        return sprite.sequence(reverse(TREE_SPOT.SPRITES.plant), TREE_SPOT.WITHER_DURATION, t - tree_spot.t_cut)
    end

    return nil
end

function TREE_SPOT.create_node(tree_spot, parent, state)
    assert(tree_spot.node == nil)
    tree_spot.node = NODE.add_node(tree_spot.x, tree_spot.y, parent, state, NODE_TYPE.TREE)
    return tree_spot.node
end

function TREE_SPOT.age(tree_spot, t)
    if tree_spot.t_grown == NEVER then
        return 0
    end
    return t - tree_spot.t_grown
end

function TREE_SPOT.since_cut(tree_spot, t)
    if tree_spot.t_cut == NEVER then
        return 0
    end
    return t - tree_spot.t_cut
end

function TREE_SPOT.find_tree_spot(tree_spots, x, y)
    for _, tree_spot in ipairs(tree_spots) do
        if tree_spot.node == nil and sq_dist(x, y, tree_spot.x, tree_spot.y) < TREE_SPOT.RADIUS ^ 2 then
            return tree_spot
        end
    end
    return nil
end
