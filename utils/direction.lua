Direction = Enum("LEFT", "RIGHT", "UP", "DOWN")
Axis = Enum("X", "Y")
Orientation = Enum("LEFT_UP", "UP_RIGHT", "RIGHT_DOWN", "DOWN_LEFT", "LEFT_DOWN", "UP_LEFT", "RIGHT_UP", "DOWN_RIGHT")

function direction_to_angle(direction)
    if direction == Direction.RIGHT then
        return 0
    elseif direction == Direction.UP then
        return math.pi * 1.5
    elseif direction == Direction.LEFT then
    	return math.pi
    elseif direction == Direction.DOWN then
        return math.pi * 0.5
    end
    error("Invalid direction \""..details_string(direction).."\".")
end

function direction_to_x(direction)
    if direction == Direction.RIGHT then
        return 1
    elseif direction == Direction.UP then
        return 0
    elseif direction == Direction.LEFT then
        return -1
    elseif direction == Direction.DOWN then
        return 0
    end
    error("Invalid direction \""..details_string(direction).."\".")
end

function direction_to_y(direction)
    if direction == Direction.RIGHT then
        return 0
    elseif direction == Direction.UP then
        return -1
    elseif direction == Direction.LEFT then
        return  0
    elseif direction == Direction.DOWN then
        return 1
    end
    error("Invalid direction \""..details_string(direction).."\".")
end

function direction_opposite(direction)
    if direction == Direction.RIGHT then
        return Direction.LEFT
    elseif direction == Direction.UP then
        return Direction.DOWN
    elseif direction == Direction.LEFT then
        return Direction.RIGHT
    elseif direction == Direction.DOWN then
        return Direction.UP
    end
    error("Invalid direction \""..details_string(direction).."\".")
end

function direction_axis(direction)
    if (direction == Direction.RIGHT) or (direction == Direction.LEFT) then
        return Axis.X
    elseif (direction == Direction.UP) or (direction == Direction.DOWN) then
        return Axis.Y
    end
    error("Invalid direction \""..details_string(direction).."\".")
end

function primary_direction(orientation)
    if orientation == Orientation.RIGHT_UP or orientation == Orientation.RIGHT_DOWN then
        return Direction.RIGHT
    elseif orientation == Orientation.UP_LEFT or orientation == Orientation.UP_RIGHT then
        return Direction.UP
    elseif orientation == Orientation.LEFT_UP or orientation == Orientation.LEFT_DOWN then
        return Direction.LEFT
    elseif orientation == Orientation.DOWN_LEFT or orientation == Orientation.DOWN_RIGHT then
        return Direction.DOWN
    end
    error("Invalid orientation \""..details_string(orientation).."\".")
end


function secondary_direction(orientation)
    if orientation == Orientation.DOWN_RIGHT or orientation == Orientation.UP_RIGHT then
        return Direction.RIGHT
    elseif orientation == Orientation.LEFT_UP or orientation == Orientation.RIGHT_UP then
        return Direction.UP
    elseif orientation == Orientation.UP_LEFT or orientation == Orientation.DOWN_LEFT then
        return Direction.LEFT
    elseif orientation == Orientation.LEFT_DOWN or orientation == Orientation.RIGHT_DOWN then
        return Direction.DOWN
    end
    error("Invalid orientation \""..details_string(orientation).."\".")
end

function primary_axis(orientation)
    return direction_axis(primary_direction(orientation))
end

function secondary_axis(orientation)
    return direction_axis(secondary_direction(orientation))
end
