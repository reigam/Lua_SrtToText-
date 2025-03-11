-- DaVinci Resolve Lua Script: Convert Subtitle Track to Text+ Clips
local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()
local timeline = project:GetCurrentTimeline()
local mediaPool = project:GetMediaPool()

if not timeline then
    print("No active timeline found.")
    return
end

local subtitleTrackIndex = 1 -- Subtitle track index
local targetVideoTrackIndex = 5  -- Video track for Text+ elements

-- Retrieve all subtitle clips from the subtitle track
local subtitleClips = timeline:GetItemListInTrack("subtitle", subtitleTrackIndex)
if not subtitleClips or #subtitleClips == 0 then
    print("No subtitle clips found on track " .. subtitleTrackIndex)
    return
end

print("Found " .. #subtitleClips .. " subtitle clips.")

-- Find the Text+ Template in the Media Pool
local textTemplate = nil
local rootFolder = mediaPool:GetRootFolder()
local mediaItems = rootFolder:GetClipList()

for _, item in ipairs(mediaItems) do
    if item:GetName() == "Fusion Title" then
        textTemplate = item
        break
    end
end

if not textTemplate then
    print("❌ ERROR: No Text+ template found in the Media Pool.")
    print("➡️ Please create a Fusion Title, convert it to a Fusion Clip, and save it as 'Text+ Template'.")
    return
end

print("✅ Using '" .. textTemplate:GetName() .. "' as Text+ template.")

-- Loop through each subtitle clip and create a corresponding Text+ element
for _, subtitleClip in ipairs(subtitleClips) do
    local startFrame = subtitleClip:GetStart()
    local endFrame = subtitleClip:GetEnd()
    local duration = endFrame - startFrame
    local subtitleText = subtitleClip:GetName()

    -- Add the Text+ clip to the timeline
    local newClip = {
        mediaPoolItem = textTemplate,
        trackIndex = targetVideoTrackIndex,
        recordFrame = startFrame,
        startFrame = 0,
        endFrame = duration
    }

    mediaPool:AppendToTimeline({newClip})

    -- Get the newly added clip
    local addedClips = timeline:GetItemListInTrack("video", targetVideoTrackIndex)
    local addedClip = addedClips[#addedClips]

    if addedClip then
        local fusionComp = addedClip:GetFusionCompByIndex(1)
        if fusionComp then
            local tools = fusionComp:GetToolList()
            for _, tool in pairs(tools) do
                local toolName = tool:GetAttrs()["TOOLS_Name"]
                if string.match(toolName, "Template") then
                    tool:SetInput("StyledText", subtitleText)
                    print("✅ Updated " .. toolName .. " with text: " .. subtitleText)
                    break
                end
            end
        else
            print("❌ No Fusion composition found for clip at frame " .. startFrame)
        end
    end

    print("✅ Added Text+ for subtitle: " .. subtitleText)
end

print("🎉 Conversion complete. All subtitles have been transformed into standalone Text+ clips.")
