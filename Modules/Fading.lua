local _, Private = ...
-- namespaces for functions that are called between files
local Main = Private.Main
local Config = Private.Config
local Fading = Private.Fading

local FADE_QUEUE = {}
local totalElapsed = 0
local FADE_THROTTLE = 0.02
local pendingFades = {}
Fading.offsetForFadeDelay = 0

local function PickPreferredAlpha(a1, a2, mode)
    local maxMin = mode == 1 and max or min
    return a1 and maxMin(a1, a2) or a2
end

local function GetCurrentAlpha(group)
    -- getting current alpha value so fades can reverse smoothly if necessary.
    -- checking alpha of two frames and picking the lower one, in case a random frame was stuck or reset.
    local alphaFrame
    local idleAlpha = group.config.idleAlpha

    for _, frame in pairs(group.frames) do
        if frame:IsVisible() then
            if alphaFrame then
                return min(alphaFrame, frame:GetAlpha())
            end
            alphaFrame = frame:GetAlpha()
        end
    end

    group.states.lastAlpha = group.states.lastAlpha or alphaFrame or idleAlpha
    return alphaFrame or idleAlpha
end

local function GetTargetAlpha(group)
    local alpha
    local activeConditions = group.states.activeConditions

    for _, cAlpha in pairs(activeConditions.priority) do
        if cAlpha then
            alpha = PickPreferredAlpha(alpha, cAlpha, group.config.prioAlphaPref)
        end
    end

    if alpha then
        group.states.priorityFade = true
        return alpha
    else
        group.states.priorityFade = false
    end

    for i, cAlpha in pairs(activeConditions.normal) do
        if cAlpha then
            alpha = PickPreferredAlpha(alpha, cAlpha, group.config.normalAlphaPref)
        end
    end

    return alpha or group.config.idleAlpha
end

function Fading.SetAllAlpha(targetAlpha)
    for _, group in ipairs(Main.activeGroups) do
        local newAlpha = targetAlpha or GetTargetAlpha(group)
        group.states.endAlpha = newAlpha
        for _, frame in pairs(group.frames) do
            if frame._origSetAlpha then
                frame:_origSetAlpha(newAlpha)
            else
                frame:SetAlpha(newAlpha)
            end
        end
    end
    Fading.UpdateAllFrameVisibility()
end

------------------
-- Fade Stuff
------------------

function AutoHide_FrameFade_OnUpdate(self, elapsed)
    totalElapsed = totalElapsed + elapsed
    if totalElapsed < FADE_THROTTLE then
        return
    end

    -- if throttle is lower than current framerate, we use this to adjust alphaStep
    local framerateDiff = totalElapsed/FADE_THROTTLE

    local index = 1
	local frame, fadeInfo, newAlpha

	while FADE_QUEUE[index] do
		frame = FADE_QUEUE[index]
		fadeInfo = FADE_QUEUE[index].fadeInfo
		fadeInfo.fadeTimer = fadeInfo.fadeTimer + totalElapsed

		if fadeInfo.fadeTimer < fadeInfo.timeToFade then
            newAlpha = fadeInfo.currentAlpha + (fadeInfo.alphaStep * framerateDiff)
            fadeInfo.alphaFunc(frame, newAlpha)
            fadeInfo.currentAlpha = newAlpha
		else
			fadeInfo.alphaFunc(frame, fadeInfo.endAlpha)
            tDeleteItem(FADE_QUEUE, frame)
            if fadeInfo.finishedFunc then
                fadeInfo.finishedFunc(fadeInfo.finishedArg1, fadeInfo.finishedArg2, fadeInfo.finishedArg3, fadeInfo.finishedArg4)
                fadeInfo.finishedFunc = nil
            end
		end

		index = index + 1
	end

    totalElapsed = 0

	if #FADE_QUEUE == 0 then
		self:SetScript("OnUpdate", nil)
	end
end

function Fading.StopFadeAnimations()
    wipe(FADE_QUEUE)
end

function Fading.SetVisibilityFromAlpha(frame, endAlpha, threshold)
    if Main.inCombat and frame:IsProtected() then
        return
    end

    if endAlpha > threshold then
        frame:Show()
    else
        frame:Hide()
    end
end

local function UpdateFrameVisibility(frame, frameInfo)
    if (Main.inCombat and frame:IsProtected()) or not frameInfo then
        return
    end

    local isShown = frame:IsShown()

    if frameInfo.group.states.endAlpha >= frameInfo.threshold and not isShown then
        frame:Show()
    elseif frameInfo.group.states.endAlpha < frameInfo.threshold and isShown then
        frame:Hide()
    end
end

function Fading.UpdateAllFrameVisibility(setVisibilityToValue)
    for frame, frameInfo in pairs(Main.framesThatToggleVisibility) do
        if frameInfo.isInUse then
            if setVisibilityToValue == nil or not frame:IsProtected() then
                UpdateFrameVisibility(frame, frameInfo)
            elseif setVisibilityToValue then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end
end

local function HandleVisibilityForFade(frame, fadeInfo)
    if not Main.framesThatToggleVisibility[frame] then
        return
    end
    if fadeInfo.mode == "OUT" then
        fadeInfo.finishedFunc = UpdateFrameVisibility
        fadeInfo.finishedArg1 = frame
        fadeInfo.finishedArg2 = Main.framesThatToggleVisibility[frame]
    else
        UpdateFrameVisibility(frame, Main.framesThatToggleVisibility[frame])
    end
end

function Fading.IsFadeInProgress(states)
    return GetTime() < states.fadeEndTime
end

local function CancelPendingFade(group)
    if pendingFades[group] and pendingFades[group].timer then
        pendingFades[group].timer:Cancel()
        pendingFades[group] = nil
    end
end

local function PlayFadeAnimation(group, alphaStep)
    for _, frame in pairs(group.frames) do
        tDeleteItem(FADE_QUEUE, frame) -- in case user managed to add frames to multiple groups
        frame.fadeInfo = {
            mode = group.states.fadeMode,
            timeToFade = group.config.timeToFade,
            startAlpha = group.states.startAlpha,
            endAlpha = group.states.endAlpha,
            alphaFunc = frame._origSetAlpha or frame.SetAlpha,
            currentAlpha = group.states.startAlpha,
            fadeTimer = 0,
            alphaStep = alphaStep
        }
        HandleVisibilityForFade(frame, frame.fadeInfo)
        tinsert(FADE_QUEUE, frame)
    end

    Main.frame:SetScript("OnUpdate", AutoHide_FrameFade_OnUpdate)
end

local function FadeImmediately(group)
    for _, frame in pairs(group.frames) do
        local alphaFunc = frame._origSetAlpha or frame.SetAlpha
        alphaFunc(frame, group.states.endAlpha)

        local frameVisibilityInfo = Main.framesThatToggleVisibility[frame]
        if frameVisibilityInfo then
            UpdateFrameVisibility(frame, frameVisibilityInfo)
        end
    end
end

local function ApplyFade(group, targetAlpha)
    CancelPendingFade(group)

    local states = group.states

    if Fading.IsFadeInProgress(states) then
        states.startAlpha = GetCurrentAlpha(group)
    else
        states.startAlpha = states.endAlpha
    end

    states.endAlpha = targetAlpha
    states.fadeEndTime = GetTime() + group.config.timeToFade

    local requiredSteps = max(1, group.config.timeToFade / FADE_THROTTLE)

    if requiredSteps >= 2 then
        local alphaDiff = states.endAlpha - states.startAlpha
        local alphaStep =  alphaDiff / requiredSteps
        PlayFadeAnimation(group, alphaStep)
    else
        FadeImmediately(group)
    end

end

local function ScheduleFade(group, targetAlpha, delay, fadeMode)
    local pendingFade = pendingFades[group]
    if pendingFade and pendingFade.fadeMode ~= fadeMode then
        CancelPendingFade(group)
    elseif pendingFade then
        pendingFade.targetAlpha = targetAlpha
        return
    end

    local timer = C_Timer.NewTimer(delay, function()
        local fadeInfo = pendingFades[group]
        if not fadeInfo then
            return
        end

        local currentTarget = GetTargetAlpha(group)
        if currentTarget == fadeInfo.targetAlpha then
            ApplyFade(group, currentTarget)
        end

        pendingFades[group] = nil
    end)

    pendingFades[group] = {
        timer = timer,
        fadeMode = fadeMode,
        targetAlpha = targetAlpha,
    }
end

local function ShouldDelayFade(group)
    local fadeInDelay = group.config.fadeInDelay + Fading.offsetForFadeDelay
    local fadeOutDelay = group.config.fadeOutDelay + Fading.offsetForFadeDelay
    if group.states.fadeMode == "IN" and fadeInDelay > 0 then
        return true, group.config.fadeInDelay
    elseif group.states.fadeMode == "OUT" and fadeOutDelay > 0 then
        return true, group.config.fadeOutDelay
    else
        return false, 0
    end
end

function Fading.FadeGroup(group)
    local targetAlpha = GetTargetAlpha(group)

    if targetAlpha == group.states.endAlpha then
        CancelPendingFade(group)
        return
    end

    local fadeMode = targetAlpha > group.states.endAlpha and "IN" or "OUT"
    group.states.fadeMode = fadeMode

    local shouldDelayFade, delay = ShouldDelayFade(group)
    if shouldDelayFade then
        ScheduleFade(group, targetAlpha, delay, fadeMode)
    else
        ApplyFade(group, targetAlpha)
    end
end

function Fading.FadeAllGroups()
    for _, group in ipairs(Main.activeGroups) do
        Fading.FadeGroup(group)
    end
end

function Fading.ResetPendingFades()
    for _, fadeInfo in ipairs(pendingFades) do
        if fadeInfo and fadeInfo.timer then
            fadeInfo.timer:Cancel()
        end
    end
    wipe(pendingFades)
end