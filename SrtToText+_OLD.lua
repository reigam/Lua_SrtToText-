-- DaVinci Resolve Lua Script: Convert Subtitle Track to Text+ Clips (as Clips, Not Fusion Titles)

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

-- Debug: Print all media pool items
print("Scanning Media Pool for a Text+ template...")

local textTemplate = nil
local rootFolder = mediaPool:GetRootFolder()
local mediaItems = rootFolder:GetClipList()

print("Items in Media Pool:")
for _, item in ipairs(mediaItems) do
    print("- " .. item:GetName())
end

-- Look for a saved Text+ Template in the Media Pool
for _, item in ipairs(mediaItems) do
    if item:GetName() == "Text+ Template" then
        textTemplate = item
        break
    end
end

if not textTemplate then
    print("❌ ERROR: No Text+ template found in the Media Pool.")
    print("➡️  Make sure you manually add a Text+ clip, convert it to a Compound Clip, and rename it to 'Text+ Template'.")
    return
end

print("✅ Using '" .. textTemplate:GetName() .. "' as Text+ template.")

-- Loop through each subtitle clip and create a corresponding Text+ element
for _, subtitleClip in ipairs(subtitleClips) do
    local startFrame = subtitleClip:GetStart()
    local endFrame = subtitleClip:GetEnd()
    local duration = endFrame - startFrame
    local subtitleText = subtitleClip:GetName()  -- Get subtitle text

    -- Add the Text+ clip to the timeline at the correct position
    local newClip = {
        mediaPoolItem = textTemplate,
        trackIndex = targetVideoTrackIndex,
        recordFrame = startFrame,
        startFrame = 0,
        endFrame = duration
    }

    -- Append the compound clip (not Fusion Title) to the timeline
    mediaPool:AppendToTimeline({newClip})

    -- Get the newly added clip
    local addedClips = timeline:GetItemListInTrack("video", targetVideoTrackIndex)
    local addedClip = addedClips[#addedClips]

    if addedClip then
        -- Modify the Text+ content inside the Compound Clip
        local fusionComp = addedClip:GetFusionCompByIndex(1)
        if fusionComp then
            local textPlus = fusionComp:FindTool("TextPlus1")
            if textPlus then
                textPlus:SetInput("StyledText", subtitleText)
            end
        end
    end

    print("✅ Added Text+ for subtitle: " .. subtitleText)
end

print("🎉 Conversion complete. All subtitles have been transformed into standalone Text+ clips.")
