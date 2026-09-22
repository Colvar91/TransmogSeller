# TransmogSeller 1.2.0

Eigenständiges WoW-Retail-Addon zum automatischen Verkauf von Ausrüstung bis zu einer selbst gewählten Gegenstandsstufe. Keine WeakAuras-Abhängigkeit. Einstellungen werden pro Charakter gespeichert.

## Sprachen und Update auf 1.2.0

Das Addon wählt seine Sprache automatisch über `GetLocale()` anhand der WoW-Clientsprache. Übersetzt sind Fenster, Buttons, Status- und Fehlermeldungen, Vorschau, Befehlshilfe und Addon-Beschreibung.

| Clientsprache | Zuordnung |
|---|---|
| Deutsch | deDE |
| Englisch | enUS / enGB |
| Französisch | frFR |
| Spanisch | esES / esMX, gemeinsame Übersetzung |
| Italienisch | itIT |
| Portugiesisch | ptBR; ptPT wird ebenfalls zugeordnet |
| Russisch | ruRU |
| Koreanisch | koKR |
| Chinesisch, vereinfacht | zhCN |
| Chinesisch, traditionell | zhTW |

Unbekannte Clientsprachen und fehlende einzelne Übersetzungen verwenden Englisch. Eine manuelle Sprachauswahl ist nicht nötig. Nach einem Wechsel der Clientsprache wird beim nächsten Laden des Addons die passende Sprache verwendet. `/ts` und alle Unterbefehle bleiben in jeder Sprache gleich. Die Namen und Links der Gegenstände liefert der WoW-Client.

**Update von TransmogSeller 1.1.0:** Den Ordner `TransmogSeller` mit dem neuen Ordner überschreiben und `/reload` ausführen. Vorhandene Einstellungen und Ausnahmen bleiben erhalten. `Locales.lua` muss mitkopiert werden; die aktualisierte TOC lädt sie vor den anderen Lua-Dateien. Das Fenster ist für längere Übersetzungen etwas breiter.

## Installation und erster Start

1. ZIP entpacken und den Ordner **TransmogSeller** nach `World of Warcraft/_retail_/Interface/AddOns/` kopieren.
2. Die Datei muss anschließend unter `Interface/AddOns/TransmogSeller/TransmogSeller.toc` liegen, ohne zusätzlichen Zwischenordner.
3. WoW starten oder `/reload` eingeben und das Addon aktivieren.
4. Mit `/ts` das Einstellungsfenster öffnen, maximale Gegenstandsstufe eintragen und **Speichern** drücken. Alternativ funktioniert `/ts ilvl ZAHL` weiterhin.
5. **Vorschau** zeigt die passenden Gegenstände im Chat und speichert zuvor die Einstellungen. Alternativ `/ts preview` verwenden.
6. Einen Händler öffnen: Passendes Gear wird automatisch verkauft.

Ohne eingestellte Grenze verkauft das Addon nichts. Änderungen an der Grenze starten keinen Verkauf im bereits geöffneten Händlerfenster; dafür erneut öffnen oder `/ts sell` verwenden.

## Update von RaidQuickSell

RaidQuickSell in der Addon-Liste deaktivieren oder den alten Addon-Ordner entfernen, damit nicht zwei Verkäufer gleichzeitig aktiv sind. Den neuen Ordner TransmogSeller installieren und `/reload` ausführen. Durch den neuen Addon-Namen werden bisherige Einstellungen nicht automatisch übernommen: Grenze und gewünschte Optionen einmal neu setzen; bestehende Item-Ausnahmen ebenfalls neu eintragen.

## Einstellungsfenster

`/ts` öffnet und schließt ein verschiebbares Fenster. Über das Kreuz oder Escape lässt es sich ebenfalls schließen.

- Automatischer Verkauf an/aus, maximale Gegenstandsstufe und Geschwindigkeit.
- Schutz von Ausrüstungssets sowie legendären Items, Artefakten und Erbstücken.
- Ausnahmen über eine Item-ID oder einen eingefügten Itemlink schützen/freigeben; Liste im Chat anzeigen.
- **Speichern** übernimmt alle Optionen gemeinsam. Ungültige Zahlen werden abgelehnt. Eine leere Itemlevel-Grenze deaktiviert den Verkauf, bis wieder eine Grenze gesetzt ist.
- **Vorschau** speichert die Optionen und zeigt passende Gegenstände im Chat, ohne sie zu verkaufen.
- **Verkauf stoppen** beendet den aktuellen Lauf.

Das Speichern stoppt einen laufenden Verkauf. Die Automatik greift beim nächsten Händlerbesuch. Änderungen an Ausnahmen gelten sofort. Andere ungespeicherte Änderungen werden beim Schließen verworfen. Alle Einstellungen werden pro Charakter gespeichert. `/ts help` zeigt die Befehlsübersicht.

## Was verkauft wird

- Rüstung, Waffen, Ringe, Schmuckstücke, Halsketten, Umhänge, Schilde und Nebenhandgegenstände; auch Hemden und Wappenröcke, sofern verkäuflich.
- Seelengebundene und ungebundene BoE-Gegenstände werden gleich behandelt.
- Maßgeblich ist die detaillierte Gegenstandsstufe des konkreten Itemlinks, nicht eine alte Erweiterungszuordnung oder eine feste Qualitätsfarbe.
- Standardmäßig Qualität grau bis episch. Legendäre Gegenstände, Artefakte und Erbstücke sind geschützt; `/ts special off` hebt diesen Qualitätsschutz auf.
- In WoW-Ausrüstungssets gespeicherte Items sind standardmäßig geschützt; `/ts sets off` hebt diesen Schutz auf.
- Nur Rucksack und die vier regulären Taschen. Ausgerüstete Gegenstände, Bank, Kriegsmeutenbank und Reagenzientasche werden nicht durchsucht.
- Questgegenstände, ungeöffnete Beutegegenstände, nicht verkäufliche Items und Einträge auf deiner Ausnahmeliste werden ausgelassen. Unsichere oder fehlende Itemdaten werden nicht als niedrige Gegenstandsstufe gewertet.

**Die Itemlevel-Grenze gilt auch für aktuelles oder alternatives Gear in deinen Taschen.** Solche Items gegebenenfalls mit `/ts keep ITEM-ID` schützen oder in einem WoW-Ausrüstungsset speichern. Ausnahmen gelten für alle Exemplare derselben Item-ID.

Es gibt **keine Prüfung auf bereits gesammelte Transmog-Vorlagen**. Das Addon rüstet BoE-Items nicht aus und bindet sie nicht zum Lernen einer Vorlage. Wenn du eine Vorlage vor dem Verkauf sichern möchtest, erledige das vorher oder setze das Item auf die Ausnahmeliste.

## Geschwindigkeit

Standardmäßig bis zu **8 Verkaufsaufrufe alle 0,1 Sekunden**, also theoretisch 80 Aufrufe pro Sekunde. Die tatsächliche Dauer hängt von WoW, Serverantworten und gesperrten Gegenständen ab. Das ist keine garantierte Verkaufsrate.

Nicht verarbeitete Gegenstände werden nach frühestens einer Sekunde erneut versucht, maximal drei Mal pro Position. Bei hoher Latenz kann `/ts batch 4` helfen. Nach spätestens 60 Sekunden endet ein Lauf. Fehlende Itemdaten werden zunächst bis zu fünf Sekunden abgewartet. Bei verbleibenden Items kann `/ts sell` den Lauf erneut starten.

Während des Laufs Taschen möglichst nicht sortieren oder Items verschieben. Geänderte Positionen werden anhand der Item-GUID verworfen, damit kein Ersatzgegenstand versehentlich verkauft wird. Neu hinzugekommene Items werden erst im nächsten Lauf berücksichtigt.

## Befehle

| Befehl | Funktion |
|---|---|
| `/ts` | Einstellungsfenster öffnen/schließen |
| `/ts help` | Status und Befehlsübersicht |
| `/ts ilvl 100` | Maximalen Itemlevel auf 100 setzen |
| `/ts preview` | Passende Gegenstände anzeigen, ohne Verkauf |
| `/ts on` / `/ts off` | Automatik aktivieren/deaktivieren |
| `/ts sell` | Beim geöffneten Händler erneut starten |
| `/ts stop` | Lauf für diesen Besuch stoppen |
| `/ts keep 12345` | Item-ID schützen; eingefügter Itemlink geht ebenfalls |
| `/ts unkeep 12345` | Ausnahme entfernen |
| `/ts list` | Ausnahmen anzeigen |
| `/ts batch 8` | 1–12 Aufrufe je 0,1 Sekunden; Standard 8 |
| `/ts sets on` / `off` | Schutz für WoW-Ausrüstungssets |
| `/ts special on` / `off` | Schutz für legendäre Items, Artefakte und Erbstücke |

**Shift beim Händleröffnen gedrückt halten:** Diesen Besuch auslassen. Shift während eines Laufs stoppt ihn. Händler schließen, Kampf oder ein Gegenstand am Mauszeiger stoppen den Verkauf ebenfalls.

## Prüfung und Grenzen

32 Verhaltenstests mit Lua 5.1 und nachgebildeten WoW-APIs wurden für 14 Locale-Fälle ausgeführt (448 erfolgreiche Testläufe). Hinzu kommen Tests für den Fallback eines fehlenden Übersetzungseintrags und den Erhalt gespeicherter Einstellungen. Geprüft sind alle 55 Übersetzungseinträge pro Sprachfassung, Format-Platzhalter, UI-Beschriftungen, Verkaufsfilter, BoE/seelengebunden, volle Taschen, fehlende Daten, Wiederholungen, Abbruchbedingungen und Fensteraktionen. Der Nutzer hat den Verkauf der Vorgängerversion im Spiel bestätigt. Darstellung und Zeilenumbrüche der Übersetzungen wurden noch nicht im WoW-Client geprüft. Blizzard-Bestätigungsdialoge werden nicht automatisch bestätigt; solche Items können liegen bleiben.

Die Rückkauf-Liste des Händlers ist begrenzt: Bei einem großen Verkauf ist sie kein vollständiges Undo. Das Addon löscht keine Gegenstände; es verwendet ausschließlich den Händler-Verkaufsweg.

TOC-Kennungen für Retail 12.1.0 und mehrere 12.0-Versionen enthalten. Falls WoW das Addon nach einem Patch als veraltet markiert, kann „Veraltete Addons laden“ nötig sein; das garantiert keine API-Kompatibilität. Fehlertext bitte zusammen mit der WoW-Version melden.

## Referenzen

- Vom Nutzer genannte Referenz: [Sell Old Content Armor and Weapons Button](https://wago.io/bpmz78RWf), v1.0.17 vom 25.07.2025, für 11.1.7 gekennzeichnet. Beschreibung: anklickbarer Verkauf im konfigurierten Itemlevel-Bereich, mit Throttle-Option. Keine Übernahme oder Ausführung des WeakAura-Codes.
- [Blizzards exportierte Container-API-Dokumentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)
- [Blizzards exportierte Item-API-Dokumentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
