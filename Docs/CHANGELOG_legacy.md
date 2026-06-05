# DelveTracker Slayer Alliance Edition - 3.3.1-beta-hotfix

## Fixed

- Fixed a load-blocking Lua syntax error in `Plugins/DT_prey_ui.lua` caused by unescaped texture/font paths.
- Fixed `/prey` slash command handling by replacing the invalid `string.trim` call with WoW's `strtrim`.
- Fixed PreyTracker inactive-state handling so `questID == 0` is treated as no active Prey Hunt.
- Fixed Prey objective parsing so monster/kill objectives are counted as kill progress.
- Fixed the Prey compass needle direction by using one player-relative clockwise angle convention for normal targets and trap targets.
- Fixed mixed-map waypoint calculations by only comparing player and waypoint coordinates from the same `uiMapID` when possible.
- Fixed trap targeting to prefer `C_VignetteInfo.GetVignettePosition(vignetteGUID, uiMapID)`, with the previous `mapInfo` path kept only as a fallback.
- Fixed misleading `< 1 yd` display when quest distance is unknown or cross-continent; the HUD now shows `-- yd`.
- Fixed the Prey widget hook so it can attach even when `Blizzard_UIWidgets` was already loaded.
- Fixed Prey arrow texture fallback detection so it checks whether the texture actually loaded.
- Fixed outdated README slash command documentation and added `/dt reload` plus `/dt reset` support.

## Changed

- Reduced PreyTracker quest/map/vignette polling from 50 times per second to a throttled logic update while keeping the HUD visually responsive.
- Registered `PreyTracker` in the DelveTracker plugin list so it can be toggled from the existing plugin settings.
- Updated package metadata to `3.3.1-beta-hotfix`.

## Cleaned

- Removed the duplicate unloaded `Plugins/DT_CustomAFK.lua` copy; the active AFK module remains loaded from `Plugins/afk/DT_CustomAFK.lua`.

## Notes

- This is a static package rebuild. Final validation should still be done in-game with `/console scriptErrors 1`, `/reload`, `/prey`, `/prey test`, `/prey debug`, and a real active Prey Hunt.
