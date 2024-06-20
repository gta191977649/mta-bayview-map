-- List of spotlight IDs and their animation data
local sport_lights = {
    ["VIEW_SPLIGHT_1"] = {initialAngle = 0, amplitude = 30, period = 3000, targetAxis = "X", speedFactor = 0.1},
    ["VIEW_SPLIGHT_2"] = {initialAngle = 0, amplitude = 30, period = 3000, targetAxis = "X", speedFactor = 0.15},
    ["VIEW_SPLIGHT_3"] = {initialAngle = 0, amplitude = -25, period = 3000, targetAxis = "X", speedFactor = 0.2},
    -- Define more spotlights with respective initial angles, amplitude, period, target axis, and speed factor
}

-- Variable to track time
local accumulatedTime = {}

-- Pre-render event handler to update spotlight rotation using a sine wave, timeSlice, target axis, and speed factor
addEventHandler("onClientPreRender", root,
    function(timeSlice)
        for spotlightID, data in pairs(sport_lights) do
            local spotlight = getElementByID(spotlightID)
            if spotlight then
                -- Initialize or update the accumulated time for each spotlight
                if not accumulatedTime[spotlightID] then
                    accumulatedTime[spotlightID] = 0
                end
                -- Adjust timeSlice by speed factor before adding to accumulated time
                accumulatedTime[spotlightID] = (accumulatedTime[spotlightID] + timeSlice * data.speedFactor) % data.period

                -- Calculate the sine wave-based rotation
                local phase = (accumulatedTime[spotlightID] / data.period) * 2 * math.pi  -- Complete cycle from 0 to 2π
                local sineValue = math.sin(phase)  -- Range from -1 to 1
                local newAngle = data.initialAngle + sineValue * data.amplitude

                -- Determine the axis to apply the rotation
                local x, y, z = getElementRotation(spotlight)
                if data.targetAxis == "X" then
                    x = newAngle
                elseif data.targetAxis == "Y" then
                    y = newAngle
                else  -- default to Z if unspecified
                    z = newAngle
                end
                setElementRotation(spotlight, x, y, z)
                
                -- Also update the LOD element if available
                local lodElement = getLowLODElement(spotlight)
                if lodElement and isElement(lodElement) then
                    setElementRotation(lodElement, x, y, z)
                end
            else
                outputChatBox("Spotlight not found: " .. spotlightID)
            end
        end
    end
)

