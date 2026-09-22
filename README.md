# TransmogSeller

Automatically sells armor, weapons, rings and trinkets at merchants up to your configured item level, including soulbound and unbound Bind-on-Equip items. Standalone Retail addon; no WeakAuras dependency.

[Deutsch](README-DE.md) · [Download version 1.2.0](https://github.com/Colvar91/TransmogSeller/releases/tag/v1.2.0)

## Install or update

Download `TransmogSeller-1.2.0.zip` from Releases and extract it. The release ZIP contains the correctly named addon folder. If using GitHub’s source-code ZIP instead, rename its top-level folder to `TransmogSeller`.

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

32 Lua 5.1 behavior tests passed for each of 14 locale cases (448 runs), plus missing-key fallback and saved-settings preservation tests. All 55 strings per language, format placeholders and UI labels were checked. These use mocked WoW APIs. Selling in the previous version was confirmed by the user; translated layout and wrapping have not been visually tested in the live WoW client.

## Development tests

Install the test dependency with `python -m pip install -r tests/requirements.txt`, then run `python tests/test_addon.py`. Tests use Lua 5.1 and mocked WoW APIs. No test dependencies are needed to run the addon in WoW.
