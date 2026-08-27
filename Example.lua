-- Load the Oversimplified library using the provided URL
local Oversimplified = loadstring(game:HttpGet("https://raw.githubusercontent.com/d1versity/Oversimplified/refs/heads/main/Library.lua"))() 

-- 1. Create the Main Window
-- The first argument is the Hub Title, and the second is the Key string. 
-- Leave the second argument blank ("") if you don't want a key system.
local Window = Oversimplified:CreateWindow("Oversimplified Demo", "Key123")

-- Send a startup notification
-- Arguments: Title, Description, Duration (in seconds)
Window:Notify("Welcome!", "The UI has successfully loaded.", 5)

-- 2. Create Tabs
local MainTab = Window:CreateTab("Main Features")
local ExtrasTab = Window:CreateTab("Extra Features")

-- 3. Populate the Main Tab with Elements
-- Paragraph & Label
MainTab:CreateParagraph("Information", "This is an example script showcasing the Oversimplified UI library's features.")
MainTab:CreateLabel("Interactable Elements:")

-- Button
local myButton = MainTab:CreateButton("Click Me!", function()
    Window:Notify("Button Clicked", "You clicked the test button!", 3)
end)

-- Toggle
local myToggle = MainTab:CreateToggle("Auto-Farm", false, function(state)
    print("Toggle state changed to: ", state)
end)

-- Slider
-- Arguments: Title, Min Value, Max Value, Default Value, Callback
local mySlider = MainTab:CreateSlider("WalkSpeed", 16, 100, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)

-- Input Box
-- Arguments: Title, Placeholder Text, ClearOnLeave (boolean), Callback
local myInput = MainTab:CreateInput("Target Player", "Username...", false, function(text)
    print("Input recorded: ", text)
end)

-- Dropdown
-- Arguments: Title, Options Table, Default Option, Callback
local myDropdown = MainTab:CreateDropdown("Select Weapon", {"Sword", "Bow", "Magic"}, "Sword", function(selectedOption)
    print("Equipped: ", selectedOption)
end)

-- Keybind
-- Arguments: Title, Default Key, Callback
local myKeybind = MainTab:CreateKeybind("Toggle UI", Enum.KeyCode.RightShift, function(key)
    print("Keybind pressed: ", tostring(key))
end)

-- Color Picker
-- Arguments: Title, Default Color, Callback
local myColorPicker = MainTab:CreateColorPicker("ESP Color", Color3.fromRGB(255, 0, 0), function(color)
    print("New color selected: ", tostring(color))
end)

-- 4. Showcasing Element Updates (The :Set() Methods)
ExtrasTab:CreateParagraph("Dynamic Updates", "Elements can be updated dynamically via code.")

ExtrasTab:CreateButton("Update Elements in Main Tab", function()
    -- Most elements return an object that can be manipulated later
    myButton:Set("I was changed!")
    myToggle:Set(true, "Auto-Farm (Forced On)")
    mySlider:Set(50)
    myInput:Set("New Target", "Target Player (Updated)")
    myDropdown:Set("Magic")
    myDropdown:Refresh({"Dagger", "Spear", "Magic"}, "Dagger")
    myColorPicker:Set(Color3.fromRGB(0, 255, 0), "ESP Color (Green)")
    
    Window:Notify("Updated!", "Check the Main Tab to see the changes.", 3)
end)

ExtrasTab:CreateButton("Unload UI", function()
    Window:Unload()
end)

-- 5. Add the Built-in Hub Settings Tab
-- This automatically generates a tab for background toggling, identity hiding, and a config saving/loading system.
Window:AddHubSettingsTab()
