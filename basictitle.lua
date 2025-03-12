-- DaVinci Resolve Lua Script: Convert Subtitle Track to Basic Title Clips
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
local targetVideoTrackIndex = 5  -- Video track for Basic Title elements

-- Retrieve all subtitle clips from the subtitle track
local subtitleClips = timeline:GetItemListInTrack("subtitle", subtitleTrackIndex)
if not subtitleClips or #subtitleClips == 0 then
    print("No subtitle clips found on track " .. subtitleTrackIndex)
    return
end

print("Found " .. #subtitleClips .. " subtitle clips.")

-- Find the Basic Title Template in the Media Pool
local textTemplate = nil
local rootFolder = mediaPool:GetRootFolder()
local mediaItems = rootFolder:GetClipList()

for _, item in ipairs(mediaItems) do
    if item:GetName() == "Rich" then  -- Ensure the correct name
        textTemplate = item
        break
    end
end

if not textTemplate then
    print("❌ ERROR: No Basic Title template found in the Media Pool.")
    print("➡️ Please add a Basic Title to the timeline, customize it, and save it as 'Basic Title'.")
    return
end

print("✅ Using '" .. textTemplate:GetName() .. "' as Basic Title template.")

-- Loop through each subtitle clip and create a corresponding Basic Title element
for _, subtitleClip in ipairs(subtitleClips) do
    local startFrame = subtitleClip:GetStart()
    local endFrame = subtitleClip:GetEnd()
    local duration = endFrame - startFrame
    local subtitleText = subtitleClip:GetName()

    -- Add the Basic Title clip to the timeline
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
        -- Modify the Basic Title's text
        addedClip:SetProperty("Text", subtitleText)
        print("✅ Updated Basic Title with text: " .. subtitleText)
    else
        print("❌ Failed to retrieve Basic Title clip at frame " .. startFrame)
    end

    print("✅ Added Basic Title for subtitle: " .. subtitleText)
end

print("🎉 Conversion complete. All subtitles have been transformed into Basic Title clips.")
