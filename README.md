# TransmogSeller

Automatically sells armor, weapons, rings and trinkets at merchants up to your configured item level, including soulbound and unbound Bind-on-Equip items. Standalone Retail addon; no WeakAuras dependency.

[Deutsch](README-DE.md) · [Download 1.3.0](https://github.com/Colvar91/TransmogSeller/releases/tag/v1.3.0)

![TransmogSeller logo](branding/TransmogSeller-CurseForge.png)

## Install or update

Download the addon ZIP from Releases; it contains the correctly named folder. If using GitHub’s source ZIP instead, rename the top-level folder to `TransmogSeller`.

Copy the `TransmogSeller` folder into `World of Warcraft/_retail_/Interface/AddOns/`, then run `/reload` or restart WoW. When updating from TransmogSeller 1.1.0, overwrite the addon files; character settings and item exceptions are preserved. Include the new `Locales.lua` and updated TOC file.

If migrating from the old RaidQuickSell addon, disable RaidQuickSell and configure TransmogSeller once. Do not run both sellers at the same time.

## Settings

Open the settings window with `/ts`. Set a maximum item level and click **Save**. The limit is inclusive; a blank limit prevents selling. **Preview** saves the settings and lists matching items in chat without selling. Changes apply to the next selling run. Open a merchant to start automatically.

The window includes automatic selling, speed (1–12 requests every 0.1 seconds, default 8), equipment-set protection, legendary/artifact/heirloom protection, item-ID exceptions, preview and stop buttons. Exceptions are applied immediately; other unsaved edits are discarded when closing the window. Settings are per character.

Hold Shift when opening a merchant to skip that visit. Holding Shift during a selling run stops it. Closing the merchant, entering combat or picking up an item onto the cursor also stops the run.

## Automatic language selection

The WoW client language selects the UI and chat language automatically: English, German, French, Spanish, Italian, Brazilian Portuguese, Russian, Korean, Simplified Chinese or Traditional Chinese. enGB uses English, esMX uses the shared Spanish translation, and ptPT is mapped to Brazilian Portuguese. Unknown locales and missing translation entries fall back to English. Item names are provided by WoW. Commands remain identical in all languages.

## Commands

| Command | Action |
|---|---|
| `/ts` | Toggle settings |
| `/ts help` | Status and command help |
| `/ts ilvl NUMBER` | Set inclusive maximum item level |
| `/ts on` / `/ts off` | Enable/disable automatic selling |
| `/ts preview` | Preview candidates using saved settings |
| `/ts sell` | Restart selling at an open merchant |
| `/ts stop` | Stop this selling run |
| `/ts keep ID` / `/ts unkeep ID` | Protect/unprotect an item ID; links also accepted |
| `/ts list` | Print item exceptions |
| `/ts batch NUMBER` | Set speed, 1–12 requests per 0.1 seconds |
| `/ts sets on` / `/ts sets off` | Equipment-set protection |
| `/ts special on` / `/ts special off` | Legendary/artifact/heirloom protection |

## Selling scope

Only the backpack and four regular bags are scanned. Equipped items, banks and the reagent bag are excluded. Equipment-set items and legendary/artifact/heirloom items are protected by default. Quest items, unopened loot containers, unsellable items and item-ID exceptions are skipped. Missing item data never counts as item level zero.

The limit also applies to current or alternative gear in your bags. Add exceptions for anything you want to keep. There is no collected-transmog check: the addon does not equip or bind BoE items to learn appearances. A merchant's limited buyback list is not a complete undo for a bulk sale.

Actual speed depends on WoW and server responses. Failed requests are retried at most three times per position; a run ends within 60 seconds. Avoid sorting or moving items during selling: changed item GUIDs are skipped. Blizzard confirmation dialogs are not automatically accepted.

## Validation

42 Lua 5.1 behavior tests passed for each of 14 locale cases (588 runs), plus missing-key fallback and saved-settings preservation tests. All 68 strings per language, format placeholders and UI labels were checked. These use mocked WoW APIs. Selling in the previous version was confirmed by the user; translated layout and wrapping have not been visually tested in the live WoW client.


## New in 1.3.0: filters and visual theme

The `/ts` window now has **General** and **Filters** tabs with square purple controls and gold text. Checked filters allow selling; unchecked filters retain those items. Eight categories cover armor, weapons, rings, trinkets, necklaces, cloaks, shields/held off-hands, and shirts/tabards. Off-hand weapons belong to Weapons. Separate checkboxes allow soulbound and unbound items (including BoE).

Filters default to enabled on upgrade, preserving previous behavior. Existing saved exclusions persist. The item-level limit, protection options and item-ID exceptions always take precedence. Click **Save** to apply filters; switching tabs retains draft edits and closing the window discards them. Item exceptions now live in the Filters tab and still apply immediately.

The new controls are translated in all ten language variants. The CurseForge logo is a separate branding asset and is not required to run the addon. The redesigned window has not yet been visually verified in the live WoW client.

## Development tests

Run `python -m pip install -r tests/requirements.txt`, then `python tests/test_addon.py`. Dependencies are only needed for development tests.
