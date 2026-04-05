# Changelog

All notable changes to LFG Mythic+ will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.0.3] - 2026-04-05

### Fixed
- Hardened compatibility with Raider.IO tooltip overlap, which was causing UI
  conflicts over the LFG Mythic+ window
- Added extra protection to reduce the chance of future tooltip layering /
  frame overlap issues

## [1.0.2] - 2026-04-05

### Fixed
- Spec icon resolution now uses `C_Spell.GetSpellTexture` with fallback to
  `GetSpellTexture` for compatibility across API versions
- Hardened spec discovery loop to handle both struct-return and multi-return
  forms of `GetSpecializationInfoForClassID` (WoW 12.0+ API variants)

## [1.0.1] - 2026-04-05

### Fixed
- Removed stale window-position keys (`windowPoint`, `windowX`, `windowY`,
  `windowWidth`, `windowHeight`, `locked`) from SavedVariables on load;
  the panel is now permanently anchored to PVEFrame with no user repositioning

## [1.0.0] - 2026-04-05

### Added
- Initial public release
- Companion panel anchored to the right of the Blizzard Group Finder (PVEFrame)
- Role composition display: Tank / Healer / 3× DPS slots with spec icons
  and class-colored names
- Utility coverage section: Battle Res, Bloodlust, Interrupt, Stun, Dispel,
  Soothe — always visible, greyed out when not covered
- Raid buff tracking: Arcane Intellect, Battle Shout, Power Word: Fortitude,
  Mark of the Wild, Mystic Touch, Chaos Brand, Hunter's Mark, Devotion Aura,
  Skyfury, Blessing of the Bronze, Atrophic Poison — shown only when covered
- Per-row contributor icons and tooltips showing which player provides each
  utility or buff
- Missing critical utility indicators (Bloodlust, Battle Res) on the section
  header, toggleable via `/lfgmp warnings`
- GUID-keyed spec cache immune to unit-token reassignment after roster shuffles
- Serialized inspect queue (one in-flight `NotifyInspect` at a time) with
  5-second timeout and staged retry schedule (0.5 s / 1.5 s / 4 s / 8 s)
- Safety-net periodic revalidation every 10 seconds while the panel is visible
- Runtime spec discovery for specs not in the static table (e.g. new specs
  added in future patches)
- Raider.IO profile tooltip compatibility: redirects the tooltip anchor to
  appear to the right of this panel instead of overlapping it
- Blizzard Settings > AddOns panel entry
- Slash commands: `/lfgmp warnings`, `/lfgmp reset`, `/lfgmp debug`
