# LFG Mythic+

A World of Warcraft addon that adds a companion panel to the Blizzard Group
Finder, giving you a real-time composition overview while you browse or form
Mythic+ groups.

## What It Does

When you open the Group Finder (`i` or `/i`), a compact panel appears to its
right showing:

- **Role slots** — Tank / Healer / 3× DPS with spec icon, class-colored name,
  and specialization label for each current group member
- **Utility coverage** — whether your group has Battle Res, Bloodlust, Interrupt,
  Stun, Dispel, and Soothe, with contributor icons and tooltips
- **Raid buffs** — which class buffs (Arcane Intellect, Battle Shout, Mark of the
  Wild, Mystic Touch, Chaos Brand, etc.) are present, shown only when covered
- **Missing-utility warnings** — small red indicators on the header when your
  group is missing Bloodlust or Battle Res

The panel auto-hides when you close the Group Finder. No toggle needed.

## Why Use It

The default Group Finder shows you names and roles but nothing about the
utilities or buffs a composition brings. For Mythic+, knowing you have lust,
a combat res, and a kick before you invite someone matters. This addon makes
that information visible at a glance without leaving the Group Finder.

## Key Features

- Anchors directly to PVEFrame — no window dragging or positioning required
- Spec detection with GUID-keyed caching: survives roster shuffles and
  loading-screen transitions
- Serialized inspect queue handles party members whose spec is not yet cached,
  with automatic retries and a safety-net revalidation every 10 seconds
- Runtime spec discovery for specs added after the addon's static data was
  written (new specs are picked up automatically from the game client)
- Raider.IO compat: if Raider.IO is loaded, its profile tooltip is redirected
  to appear to the right of this panel instead of overlapping it
- Registered in **Settings → AddOns** under "LFG Mythic+"

## Compatibility

- **WoW version:** The War Within (retail)
- **Interface:** 120000 / 120001
- **Optional dependency:** Raider.IO (tooltip positioning fix applied
  automatically when present)

## Installation

### Manual

1. Download the latest release zip from the [Releases](../../releases) page
2. Extract the `LFGMythicPlus` folder into:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. The folder structure must be:
   ```
   AddOns\
   └─ LFGMythicPlus\
      ├─ LFGMythicPlus.toc
      ├─ Core\
      ├─ Data\
      ├─ Modules\
      ├─ UI\
      └─ Utils\
   ```
4. Launch WoW or type `/reload` in-game

### CurseForge / Wago (if listed)

Install via your preferred addon manager.

## Usage

1. Open the Group Finder with `i` or the social panel
2. The LFG Mythic+ panel appears automatically to the right
3. Hover any slot or row for a tooltip with details
4. The panel updates live as your party composition changes

## Slash Commands

| Command | Effect |
|---|---|
| `/lfgmp` | Show command list |
| `/lfgmp warnings` | Toggle missing-utility indicators (Bloodlust / Brez) |
| `/lfgmp reset` | Reset all settings to defaults |
| `/lfgmp debug` | Toggle debug output to chat |

`/lfgmythicplus` is also registered as a full-length alias.

## Screenshots

<!-- Add screenshots here -->

## Known Limitations

- **Party only.** The addon tracks groups of up to 5. It does not show
  composition data for raids.
- **Spec detection requires proximity.** WoW's inspect API only works when the
  target is within render range. Party members outside range show a "Loading
  specs..." indicator until they are visible.
- **No LFG applicant scanning.** The panel shows your current party, not the
  list of players applying to your group in the LFG browser.

## Roadmap

- [ ] Highlight duplicate raid buffs (e.g., two Mages, zero Priests)
- [ ] Applicant preview: show a composition preview when hovering an applicant
      in the LFG browser
- [ ] Optional minimap button

## Bug Reports

Please open an issue on GitHub with:

- A description of what happened vs. what you expected
- Your WoW patch version (from the character select screen)
- Any error text from the WoW error frame or BugSack
- Whether the bug is reproducible and under what conditions

## Contributing

Pull requests are welcome. Before contributing:

1. Keep changes scoped — one concern per PR
2. Do not touch the UtilityMatrix or ClassSpecData unless you have verified the
   change in-game and cited the source (Wowhead, WoWDB, or PTR testing)
3. Do not introduce Lua globals — everything lives under the `LFGMythicPlus`
   namespace table
4. Test with and without Raider.IO loaded

## Credits

Built by **Artseeker**.

Uses only Blizzard's public addon APIs. No libraries required.

## License

[MIT](LICENSE)
