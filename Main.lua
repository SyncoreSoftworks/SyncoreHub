local loadstrings = {
    [94647229517154] = loadstring(game:HttpGet(""))();, -- Azure Latch
    [18687417158] = loadstring(game:HttpGet(""))(), -- Forsaken
    [116495829188952] = loadstring(game:HttpGet(""))(), -- Dead Rails
    [130739873848552] = loadstring(game:HttpGet(""))(), -- Basket Ball Zero
    [13076380114] = loadstring(game:HttpGet(""))(), -- Heros Battlegrounds
    [15269951959] = loadstring(game:HttpGet(""))(), -- Legends Battlegrounds
    [107040934010858] = loadstring(game:HttpGet(""))(), -- Project Egoist
    [113318245878384] = loadstring(game:HttpGet(""))(), -- Project Viltrumites
    [nil] = loadstring(game:HttpGet(""))(), -- VolleyBallZero
}

local currentPlaceID = game.PlaceId

if loadstrings[currentPlaceID] then
    local loadstringCode = loadstrings[currentPlaceID]
    loadstring(loadstringCode)()
    print("Loaded loadstring for Place ID: " .. currentPlaceID)
else
    print("No loadstring found for Place ID: " .. currentPlaceID)
end
