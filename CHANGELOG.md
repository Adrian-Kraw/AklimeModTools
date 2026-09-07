## 1.3.1

A new option to skip the non-refundable warning, plus a fix for the mana warning in instances where the game hides mana values. / Eine neue Option, um die Warnung zum Verfall der Rückerstattung zu überspringen, dazu ein Fix für die Mana-Warnung in Instanzen, in denen das Spiel die Manawerte verbirgt.

**EN**

Colorizer

* Fixed: The colored border around buff icons caused a flood of Lua errors, on the buff bar as well as on target and focus auras. The border was a backdrop frame anchored to the icon, and since the game hides aura sizes as secret values, Blizzard's backdrop code failed on every resize. The border is now drawn with four plain textures, which need no size calculation. It looks a little crisper than before.

Center Raid Frames

* New: Recentering now also happens during combat, so a group turning into a raid or a new group appearing mid fight no longer leaves the frames off center until the fight ends. The raid container is a protected frame that an addon may not move in combat, so this runs through a secure snippet inside the game's own restricted environment.
* Fixed: When a party turned into a raid, the frames stayed off center. The single attempt after the roster change ran while the raid container was still hidden or its groups were not laid out yet, and nothing tried again afterwards. Centering now also reacts to the container appearing and to it changing size.
* Fixed: The frames could end up off center, especially with a raid frame size other than the default. The width was estimated from the number of groups times one group's width, which ignored that size setting and fell back to a fixed guess when the group frames were not found. The container's own width is used now.

Quest Tracker

* Fixed: On characters whose quests are all campaign quests, the count was invisible. Campaign quests have their own section in the tracker, and the count was pinned to the header of the normal quest section, which is hidden on such a character. It now attaches to whichever quest header is actually on screen.
* Fixed: On some characters no quest count appeared at all. It was only calculated half a second after login, and the quest log arrives from the server later than that, so the result was zero and the display stayed hidden. The count now recalculates whenever the quest log changes.
* Fixed: The quest count in the tracker header did not match the quest log. World quests and bonus objectives are entries in the quest log too, but they are not quests and do not count against the limit of 35. The count now uses the same rule the quest log itself uses to decide what is a quest.

Character Tracker

* Changed: The gold overview shows exact amounts down to the copper instead of rounded values like 84.7k. Gold, silver and copper each sit in their own column, so they line up across all rows.
* New: The currencies of Midnight season 2 are tracked: the five Mistcrests, Venomblight Manaflux, Tidal Spark Dust and the Corrosive Coin.
* Fixed: The Hero Dawncrest never showed up. It was collected under the right id but looked up under a wrong one when displayed, so the row stayed empty on every character.
* Fixed: In the Great Vault the rows for raids, dungeons and world activities always showed 0/3, even on characters that had long since unlocked slots. Only the "Reward" row was right. The addon asked the game for the three categories in a way that stopped working with a patch and got nothing back. The values are correct again as soon as the character in question logs in once.
* Fixed: A typo in the German raid tooltip, "Bezwunden" instead of "Bezwungen".

Gear Check

* Fixed: Heirlooms showed the wrong item level. They scale with your character level, and the shown number was the one they start out with.
* Fixed: Your bags showed an item level. That number says nothing about your gear, it is gone. Shirt and tabard lose it as well, for the same reason.

Merchant Window

* Changed: The bottom of the widened vendor window was rebuilt. Instead of two small boxes in the right corner there is now one panel across the full width, split into two rows by a separator. The upper row carries the paging on the left and the buyback slot, sell junk and the repair buttons on the right, the lower row carries your gold at the left with the currencies this vendor accepts running to the right.
* Fixed: Only four vendor currencies were ever shown, vendors that take more than four left the rest invisible. The number now comes from the game instead of a fixed four.
* Fixed: The gold display vanished at vendors that take no gold, and the currencies then slid to the left edge. Gold now keeps its place at the left and is always shown.
* Fixed: The bottom edge of the window ended in the middle. That border is built for the original window width and was never stretched along when the window was widened.

Auto Accept Summons

* New: A delay slider from 0 to 10 seconds. At "Instant" the summon is accepted right away as before, that stays the default. With a delay you keep the chance to answer the dialog yourself during the wait, and nothing is accepted if you already did.

Auto Accept Non-Refundable Warning

* New: A third option next to the purchase and refund confirmations. It confirms the warning that an item can no longer be refunded, so the popup no longer appears. Covers all four cases that show it: equipping, using, socketing and mailing. Off by default, because that warning is the last chance to stop.

Mana Warning

* Work in progress: this feature is not finished yet.
* Fixed: In instances where the game hides mana values, the "out of mana" warning never reached the group. The game blocked it because it went out from inside one of its own routines. It is sent correctly again.
* Changed: The warnings now use the game's current chat function. The old one is only kept as a fallback, Blizzard is phasing it out.

**DE**

Einfärber

* Behoben: Der farbige Rahmen um Buff-Icons löste eine Flut von Lua-Fehlern aus, sowohl an der Buffleiste als auch bei Ziel- und Fokus-Auren. Der Rahmen war ein Backdrop-Frame, der an das Icon geheftet war, und da das Spiel Aurengrößen als geheime Werte behandelt, scheiterte Blizzards Backdrop-Code bei jeder Größenänderung. Der Rahmen besteht jetzt aus vier einfachen Texturen, die keine Größenberechnung brauchen. Er wirkt dadurch etwas klarer als vorher.

Gruppenrahmen zentrieren

* Neu: Die Zentrierung greift jetzt auch im Kampf. Wird mitten im Kampf aus einer Gruppe ein Schlachtzug oder kommt eine Gruppe dazu, stehen die Rahmen nicht mehr bis Kampfende schief. Der Schlachtzugsrahmen ist ein geschütztes Frame, das ein Addon im Kampf nicht bewegen darf, das läuft deshalb über ein Secure Snippet in der geschützten Umgebung des Spiels.
* Behoben: Wurde aus einer Gruppe ein Schlachtzug, blieben die Rahmen unzentriert. Der einzelne Versuch nach der Gruppenänderung lief zu früh, da war der Schlachtzugsrahmen noch ausgeblendet oder seine Gruppen noch nicht angeordnet, und danach passierte nichts mehr. Die Zentrierung reagiert jetzt auch darauf, dass der Rahmen erscheint und dass er seine Größe ändert.
* Behoben: Die Rahmen konnten daneben landen, vor allem bei einer anderen Rahmengröße als der Voreinstellung. Die Breite wurde aus Gruppenanzahl mal Breite einer Gruppe geschätzt, das ignorierte die eingestellte Größe und fiel auf einen festen Schätzwert zurück, wenn die Gruppenrahmen nicht gefunden wurden. Jetzt wird die tatsächliche Breite des Rahmens verwendet.

Quest-Tracker

* Behoben: Bei Charakteren, deren Quests alle Kampagnenquests sind, war die Zahl unsichtbar. Kampagnenquests haben im Tracker einen eigenen Abschnitt, die Zahl hing aber an der Kopfzeile des normalen Quest-Abschnitts, und die ist bei so einem Charakter ausgeblendet. Sie hängt sich jetzt an die Quest-Kopfzeile, die tatsächlich zu sehen ist.
* Behoben: Bei manchen Charakteren stand gar keine Questzahl da. Sie wurde nur eine halbe Sekunde nach dem Login berechnet, das Questlog kommt aber später vom Server. Das Ergebnis war dann null und die Anzeige blieb ausgeblendet. Jetzt wird bei jeder Änderung am Questlog neu gezählt.
* Behoben: Die Questzahl in der Kopfzeile passte nicht zum Questlog. Weltquests und Bonusziele sind dort ebenfalls Einträge, zählen aber nicht als Quest und nicht gegen das Limit von 35. Gezählt wird jetzt nach derselben Regel, mit der auch das Questlog entscheidet, was eine Quest ist.

Charakter-Tracker

* Geändert: Die Goldübersicht zeigt genaue Beträge bis auf den Kupfer statt gerundeter Werte wie 84,7k. Gold, Silber und Kupfer stehen in eigenen Spalten und damit über alle Zeilen untereinander.
* Neu: Die Währungen aus Season 2 von Midnight werden mitgezählt: die fünf Nebelwappen, der Gifthauchmanaflux, der Gezeitenfunkenstaub und die Korrosive Münze.
* Behoben: Das Morgenlichtwappen des Helden tauchte nie auf. Es wurde unter der richtigen Kennung eingesammelt, bei der Anzeige aber unter einer falschen gesucht, deshalb blieb die Zeile bei jedem Charakter leer.
* Behoben: Bei der Großen Schatzkammer standen Schlachtzüge, Dungeons und Weltaktivitäten immer auf 0/3, auch bei Charakteren, die längst Plätze freigeschaltet hatten. Nur die Zeile "Belohnung" stimmte. Das Addon hat die drei Kategorien auf eine Art beim Spiel abgefragt, die seit einem Patch nicht mehr funktioniert, und bekam nichts zurück. Die Werte stimmen wieder, sobald der jeweilige Charakter einmal einloggt.
* Behoben: Tippfehler im Raid-Tooltip, dort stand "Bezwunden" statt "Bezwungen".

Ausrüstungs-Prüfung

* Behoben: Erbstücke zeigten die falsche Gegenstandsstufe. Sie wachsen mit deiner Stufe mit, angezeigt wurde aber der Wert, mit dem sie anfangen.
* Behoben: An den Taschen stand eine Gegenstandsstufe. Die sagt nichts über deine Ausrüstung aus und ist weg. Hemd und Wappenrock verlieren sie aus demselben Grund.

Händlerfenster

* Geändert: Der untere Teil des verbreiterten Händlerfensters wurde neu aufgebaut. Statt zweier kleiner Kästen in der rechten Ecke gibt es jetzt eine Leiste über die volle Breite, durch eine Trennlinie in zwei Zeilen geteilt. Oben sitzt links das Blättern und rechts Rückkauf, Müll verkaufen und die Reparaturknöpfe, unten links dein Gold und daneben nach rechts die Währungen, die dieser Händler nimmt.
* Behoben: Es wurden immer nur vier Händlerwährungen angezeigt, bei Händlern mit mehr blieb der Rest unsichtbar. Die Anzahl kommt jetzt vom Spiel statt aus einer festen Vier.
* Behoben: Die Goldanzeige verschwand bei Händlern, die kein Gold nehmen, und die Währungen rutschten dann an den linken Rand. Gold behält jetzt seinen Platz links und wird immer angezeigt.
* Behoben: Der untere Fensterrand hörte auf halber Strecke auf. Diese Leiste ist für die ursprüngliche Fensterbreite gebaut und wurde beim Verbreitern nie mitgezogen.

Beschwörungen automatisch annehmen

* Neu: Ein Regler für die Verzögerung von 0 bis 10 Sekunden. Bei "Sofort" wird wie bisher direkt angenommen, das bleibt der Standard. Mit Verzögerung hast du während der Wartezeit noch die Möglichkeit, selbst auf den Dialog zu reagieren, und es wird nichts mehr angenommen, wenn du das getan hast.

Warnung zum Verfall der Rückerstattung annehmen

* Neu: Eine dritte Option neben der Kauf- und der Rückerstattungsbestätigung. Sie bestätigt die Warnung, dass ein Gegenstand nicht mehr zurückerstattet werden kann, das Fenster erscheint damit nicht mehr. Deckt alle vier Fälle ab, in denen es auftaucht: Anlegen, Benutzen, Sockeln und Verschicken per Post. Standardmäßig aus, weil diese Warnung die letzte Möglichkeit zum Abbrechen ist.

Mana-Warnung

* Baustelle: an dieser Funktion wird noch gearbeitet.
* Behoben: In Instanzen, in denen das Spiel die Manawerte verbirgt, kam die "kein Mana mehr"-Warnung nie in der Gruppe an. Das Spiel hat sie blockiert, weil sie aus einer seiner eigenen Routinen heraus verschickt wurde. Sie geht jetzt wieder korrekt raus.
* Geändert: Die Warnungen nutzen jetzt die aktuelle Chat-Funktion des Spiels. Die alte bleibt nur noch als Rückfallebene, Blizzard schafft sie ab.

## 1.3.0

A rebuilt gold overview with Warband Bank support, a tidied up mail address book, the Services channel is now hidden instead of left, and a fix for raids landing in the wrong expansion. / Eine neu gebaute Gold-Übersicht mit Kriegsmeutenbank, ein aufgeräumtes Adressbuch für Post, der Dienste-Channel wird jetzt ausgeblendet statt verlassen und ein Fix für Raids, die in der falschen Erweiterung einsortiert wurden.

**EN**

Character Tracker

* Changed: The gold overview is now its own window with several columns instead of one long list that ran off the bottom of the screen. The total across all characters sits at the top, realms are sorted by how much gold they hold.
* New: Gold in the Warband Bank is picked up when you open the bank and is counted into the total.
* Fixed: Raids were sorted into the wrong expansion. Names starting with an article and names containing an apostrophe did not match.

Address Book for Mail

* Changed: The list now holds your own characters only. Recipients are no longer saved when you send a mail.
* Fixed: Characters could show up twice, the second entry in white and without a realm.
* New: The character you sent mail to last is pinned to the top of the list.

Hide Services Channel

* Changed: The channel is no longer left, its lines are hidden in chat instead, join and leave notices included. Leaving it meant the channel stayed gone after switching the option off and logging out. The option is now called "Hide Services Channel".

Hide Talent and Profession Popups

* New: The popups about a new profession specialization and about choosing your hero talents are now hidden as well, not just the one about unspent talent points. All texts are read from the game itself, so this works on every client language.

Center Raid Frames


**DE**

Charakter-Tracker

* Geändert: Die Gold-Übersicht ist jetzt ein eigenes Fenster mit mehreren Spalten statt einer langen Liste, die unten aus dem Bild lief. Die Summe über alle Charaktere steht oben, die Realms sind nach ihrem Gold sortiert.
* Neu: Gold in der Kriegsmeutenbank wird beim Öffnen der Bank erfasst und in die Summe eingerechnet.
* Behoben: Raids wurden in der falschen Erweiterung einsortiert. Namen mit Artikel am Anfang und Namen mit Apostroph passten nicht zusammen.

Adressbuch für Post

* Geändert: In der Liste stehen jetzt nur noch deine eigenen Charaktere. Empfänger werden beim Senden nicht mehr gespeichert.
* Behoben: Charaktere konnten doppelt auftauchen, der zweite Eintrag in Weiß und ohne Realm.
* Neu: Der zuletzt beschickte Charakter steht ganz oben in der Liste.

Dienste-Channel ausblenden

* Geändert: Der Channel wird nicht mehr verlassen, stattdessen werden seine Zeilen im Chat ausgeblendet, auch Beitritts- und Verlassen-Meldungen. Durch das Verlassen blieb der Channel weg, wenn man die Option ausschaltete und sich ausloggte. Die Option heißt jetzt "Dienste-Channel ausblenden".

Talent- und Berufs-Popups ausblenden

* Neu: Auch die Hinweise zu einer neuen Berufsspezialisierung und zur Wahl der Heldentalente werden jetzt ausgeblendet, nicht mehr nur der zu unverteilten Talentpunkten. Die Texte werden aus dem Spiel selbst gelesen, das funktioniert damit in jeder Clientsprache.

Gruppenrahmen zentrieren


## 1.1.3 + 1.2.0

Fixes for the Enhanced Friends List, the profession unlearn confirmation, Easy Delete input handling, and a translation fix for the chat copy window, plus a smarter Great Vault status for characters that have not logged in yet, a Heroism Tracker click-through fix, a Minimap Button Collector fix for TomTom waypoints, a Lua error fix for the Leave Trade Channel feature, and a fix for Auto Accept Summons, plus a new average item level display and item level on bags/bank/guild bank for Gear Check. / Fixes für die verbesserte Freundesliste, die Verlernen-Bestätigung bei Berufen, Einfaches Löschen Eingabeanpassungen und einen Übersetzungsfix für das Chat-Kopierfenster, außerdem eine schlauere Schatzkammer-Anzeige für noch nicht eingeloggte Charaktere, ein Klick-durch-Fix für den Heldentum-Tracker, ein Fix im Minimap Button Sammler für TomTom-Wegpunkte, ein Lua-Fehler-Fix beim Dienste-Channel verlassen und ein Fix für Beschwörungen automatisch annehmen, außerdem eine neue Durchschnitts-Itemlevel-Anzeige und Itemlevel bei Taschen/Bank/Gildenbank für die Ausrüstungs-Prüfung.

**EN**

Enhanced Friends List

* Fixed: BNet contacts on the Battle.net mobile app were shown as offline with no status indicator. They now appear as online and show "Mobile" in the info line.

Chat Interaction

* Fixed: "Select All" and "Close" buttons in the chat copy window were not translated for German clients.

Easy Confirm and Delete

* Fixed: When unlearning a profession, the confirmation field was auto-filled with the wrong word, leaving the Unlearn button disabled. The correct confirmation word is now detected and filled in.
* Fixed: Confirming the destroy prompt for a whole item stack left the confirmation field empty because that dialog type was not recognized. Delete/destroy confirmations are now matched more broadly and no longer depend on an exact dialog list.

Character Tracker

* New: The Great Vault "Reward" row now shows "Open" for characters that have not logged in since the weekly reset, if their last known progress guarantees a reward is waiting

Heroism Tracker

* Fixed: The tracker was unlocked by default, blocking clicks on frames behind it. It is now locked by default, so it is click-through unless you unlock it to move it.

Minimap Button Collector

* Fixed: TomTom's minimap waypoint arrows (named "TTMinimapButton") could get swept into the collector and show up there as invisible icons. They are now excluded.

Leave Trade Channel

* Fixed: Rejoining the channel could throw a Lua error, because the addon tried to auto-show it in the chat window using a Blizzard API function that no longer exists. The channel is now shown correctly and without errors.

Auto Accept Summons

* Fixed: Accepting a summon no longer worked, it only closed the popup without teleporting. ConfirmSummon() was moved to C_SummonInfo.ConfirmSummon() back in patch 8.1.0 and the old function no longer exists. Summons are accepted correctly again.

Gear Check

* New: The Inspect window now shows the average item level ("GS") on the model when viewing another player, based on all equipped gear except shirt and tabard.
* New: Item level is now also shown on gear in bags, bank, Warband Bank and guild bank, not just on equipped slots.
* Fixed: Legacy items like the Heart of Azeroth and Legion artifact weapons showed a wrong, outdated item level. Their real, current level is now read from the tooltip instead.

PvP Chat Block

* New: Right-clicking the button now also hides all chat windows completely, separate from the normal PvP chat block.

Played Time

* Changed: Hours are now shown as "h" for German clients.

Set Chat Size for All Characters

* New: You can now pick a chat font size (12-27pt, same options as in-game) that gets applied automatically to characters that haven't had it set yet.

Move UI Elements

* New: You can now freely move the popup that appears when a Battle.net friend comes online. Drag it into position and lock it in place.

**DE**

Verbesserte Freundesliste

* Behoben: BNet-Kontakte über die Battle.net Mobile-App wurden als offline angezeigt und hatten keinen Status-Indikator. Sie erscheinen jetzt als online und zeigen "Mobilgerät" in der Info-Zeile.

Chat Interaktion

* Behoben: "Alles auswählen" und "Schließen" Buttons im Chat-Kopierfenster waren für deutschsprachige Nutzer auf Englisch.

Einfaches Bestätigen und Löschen

* Behoben: Beim Verlernen eines Berufs wurde im Bestätigungsfeld das falsche Wort eingetragen ("LÖSCHEN" statt "VERLERNEN"), wodurch der Verlernen-Knopf deaktiviert blieb. Das richtige Wort wird jetzt erkannt und eingetragen.
* Behoben: Einfaches Löschen Eingabeanpassungen — der Zerstören-Dialog für einen ganzen Item-Stapel wurde nicht erkannt, das Bestätigungsfeld blieb leer. Lösch-/Zerstören-Dialoge werden jetzt zuverlässiger erkannt statt über eine feste Liste.

Charakter-Tracker

* Neu: Die "Belohnung"-Zeile der Großen Schatzkammer zeigt jetzt "Offen" für Charaktere, die seit dem wöchentlichen Reset nicht eingeloggt waren, sofern der zuletzt bekannte Fortschritt eine Belohnung garantiert

Heldentum-Tracker

* Behoben: Der Tracker war standardmäßig entsperrt und blockierte dadurch Klicks auf Frames dahinter. Er ist jetzt standardmäßig gesperrt und damit click-through, außer man entsperrt ihn zum Verschieben.

Minimap Button Sammler

* Behoben: TomTom-Wegpunkt-Pfeile auf der Minimap (benannt "TTMinimapButton") konnten in den Sammler aufgenommen werden und erschienen dort als unsichtbare Icons. Sie werden jetzt ausgeschlossen.

Dienste-Channel verlassen

* Behoben: Beim erneuten Beitreten zum Channel konnte ein Lua-Fehler auftreten, weil das Addon versuchte, ihn per einer nicht mehr existierenden Blizzard-API-Funktion automatisch im Chatfenster anzuzeigen. Der Channel wird jetzt korrekt und ohne Fehler angezeigt.

Beschwörungen automatisch annehmen

* Behoben: Das Annehmen einer Beschwörung funktionierte nicht mehr, es schloss nur das Fenster ohne zu teleportieren. ConfirmSummon() wurde schon in Patch 8.1.0 zu C_SummonInfo.ConfirmSummon() verschoben, die alte Funktion existiert nicht mehr. Beschwörungen werden jetzt wieder korrekt angenommen.

Ausrüstungs-Prüfung

* Neu: Im Betrachten-Fenster wird jetzt oben am Modell das durchschnittliche Itemlevel ("GS") des angesehenen Spielers angezeigt, basierend auf der kompletten Ausrüstung außer Hemd und Wappenrock.
* Neu: Itemlevel wird jetzt auch bei Ausrüstung in Taschen, Bank, Warband-Bank und Gildenbank angezeigt, nicht mehr nur an angelegten Slots.
* Behoben: Legacy-Items wie das Herz von Azeroth und Legion-Artefaktwaffen zeigten ein falsches, veraltetes Itemlevel. Ihr echtes, aktuelles Level wird jetzt aus dem Tooltip gelesen.

Chat im PvP blockieren

* Neu: Rechtsklick auf den Button blendet jetzt zusätzlich alle Chatfenster komplett aus, unabhängig von der normalen PvP-Chat-Blockade.

Gespielte Zeit

* Geändert: Stunden werden jetzt als "h" angezeigt.

Chatgröße für alle Chars setzen

* Neu: Es lässt sich jetzt eine Chatgröße (12-27pt, gleiche Auswahl wie im Spiel) festlegen, die automatisch bei Charakteren übernommen wird, für die sie noch nicht gesetzt wurde.

UI Elemente verschieben

* Neu: Die Meldung, die beim Online-Gehen eines Battle.net-Kontakts erscheint, lässt sich jetzt frei verschieben. An die gewünschte Stelle ziehen und einrasten.


## 1.1.2

Fix for the Enhanced Friends List after Blizzard's API hotfix. / Fix für die verbesserte Freundesliste nach Blizzards API-Hotfix.

**EN**

Enhanced Friends List

* Fixed: Favorite stars flickered on and off after Blizzard's patch restored the favorites API

**DE**

Verbesserte Freundesliste

* Behoben: Favoriten-Sterne blinkten nach Blizzards Patch, der die Favoriten-API wiederhergestellt hat


## 1.1.1

Translation fixes. / Übersetzungskorrekturen.

**EN**

Chat Interaction

* Fixed: "Select All" and "Close" buttons in the chat copy window were hardcoded in German

**DE**

Chat Interaktion

* Behoben: "Alles auswählen" und "Schließen" Buttons im Chat-Kopierfenster waren auf Deutsch hardcodiert


## 1.1.0

Bug fixes for the Enhanced Friends List and Dungeon Eye, plus a new sub-toggle to hide talent point alert popups. / Bugfixes für die verbesserte Freundesliste und das Dungeon Eye, plus neuer Unter-Schalter zum Ausblenden der Talentpunkt-Popups.

**EN**

Hide Learn/Unlearn Messages

* New: Sub-toggle to hide the "You have unspent talent points" and "PvP talent slot available" alert popups

Enhanced Friends List

* Fix attempt: BNet contacts could still show an outdated zone location after the contact changed zones
* Fixed: WoW friends could remain shown as online after going offline

Dungeon Eye

* Fixed: The eye's looking animation was frozen while the Dungeon Eye feature was active

**DE**

Lernen-/Vergessen-Meldungen ausblenden

* Neu: Unter-Schalter zum Ausblenden der Popups "Ihr habt noch unverteilte Talentpunkte" und "Ihr habt einen verfügbaren PvP-Talentplatz"

Verbesserte Freundesliste

* Behebungsversuch: BNet-Kontakte konnten noch den alten Ort anzeigen, nachdem der Kontakt die Zone gewechselt hatte
* Behoben: Ingame-Freunde konnten nach dem Ausloggen noch als online angezeigt werden

Dungeon Eye

* Behoben: Die Augen-Animation (Schauen) war eingefroren solange das Dungeon-Eye-Feature aktiv war


## 1.0.0

First stable release / Erste stabile Release-Version.

**EN**

Heroism Tracker

* Fixed: BL text disappeared as soon as combat started in instances. Blizzard hides the buff data from addons in instanced combat (12.0), the tracker now derives the buff from the readable exhaustion debuff instead. Works no matter who casts BL and also covers drums

Mana Warning

* New: The warning now works. Sends one group message when your mana drops below 10%

Settings Window

* New: Complete redesign in a flat black and gold look with rounded category buttons, stone background, round addon portrait and centered window title
* New: Action buttons are now real centered buttons instead of plain clickable text
* New: Delete actions ask for confirmation with a Yes / No dialog
* New: The character delete list shows Name - Realm - Class in class colors, arranged in columns of 20
* Changed: The window turns slightly transparent while being dragged
* Fixed: Some checkboxes closed their section when clicked, sections now stay open
* Fixed: Exclusive options (for example chat fade times) could show two checkmarks at once, now exactly one is shown and it updates instantly
* Fixed: Clicking an already active option no longer removes its checkmark

Colorizer

* New: The addon window skin got more color slots: boxes, lines, selection and portrait ring, plus a "Color everything" picker and a restore default button
* New: Elite Frame can now be colored (Addons group)
* New: Game menu buttons can now be colored
* Fixed: The active chat tab and the focused chat edit box were not colored along

Character Tracker

* New: Currency amounts now update live after transferring a currency between your characters. The receiving character and the offline source character both show the new balance immediately, no relog needed

Purchase Confirmation

* Fixed: Not all high cost purchase dialogs ("buy for the following amount") were not auto-confirmed, now they are
* New: Separate toggle to auto-confirm refund dialogs when selling refundable items back to a vendor

**DE**

Heldentum-Tracker

* Behoben: HT-Text verschwand in Instanzen, sobald der Kampf begann. Blizzard versteckt die Buff-Daten im Instanz-Kampf vor Addons (12.0), der Tracker leitet den Buff jetzt stattdessen aus dem lesbaren Erschöpfungs-Debuff ab. Funktioniert egal wer HT wirkt und deckt auch Trommeln ab

Mana-Warnung

* Neu: Die Warnung arbeitet jetzt. Sendet eine Gruppennachricht, wenn das Mana unter 10% fällt. 

Einstellungsfenster

* Neu: Komplett neues Design in flachem Schwarz-Gold-Look mit abgerundeten Kategorie-Buttons, Stein-Hintergrund, rundem Addon-Portrait und mittigem Fenstertitel
* Neu: Aktions-Schaltflächen sind jetzt echte zentrierte Buttons statt klickbarer Textflächen
* Neu: Lösch-Aktionen fragen vorher mit einem Ja / Nein-Dialog nach
* Neu: Die Char-Löschen-Liste zeigt Name - Server - Klasse in Klassenfarben, aufgeteilt in Spalten zu je 20
* Geändert: Das Fenster wird beim Verschieben leicht transparent
* Behoben: Manche Haken haben beim Anklicken ihre Sektion zugeklappt, Sektionen bleiben jetzt offen
* Behoben: Bei exklusiven Optionen (z.B. Chat-Verblassen-Zeiten) konnten zwei Haken gleichzeitig zu sehen sein, jetzt ist immer genau einer gesetzt und er aktualisiert sich sofort
* Behoben: Klick auf eine bereits aktive Option entfernt deren Haken nicht mehr

Colorizer

* Neu: Der Skin für das Addon-Fenster hat mehr Farbfelder: Boxen, Linien, Auswahl und Portrait-Ring, dazu "Alles färben" und einen Standard-Button
* Neu: Elite Frame ist jetzt färbbar (Gruppe Addons)
* Neu: Die Spielmenü-Buttons sind jetzt färbbar
* Behoben: Der aktive Chat-Reiter und die fokussierte Eingabezeile wurden nicht mitgefärbt

Charakter-Tracker

* Neu: Währungsstände aktualisieren sich jetzt live nach einem Währungstransfer zwischen deinen Charakteren. Empfangender und abgebender Charakter (auch offline) zeigen sofort den neuen Stand, kein Relog nötig

Kaufbestätigung

* Behoben: Nicht alle teure Kaufdialoge ("für den folgenden Betrag kaufen") wurden nicht automatisch bestätigt, jetzt schon
* Neu: Eigener Schalter, der Rückerstattungsdialoge beim Rückverkauf umtauschbarer Items automatisch bestätigt


## 0.9.6

**EN**

Friends List

* Fixed: Visiting a friend's house from the contacts frame could cause an ADDON_ACTION_FORBIDDEN error due to the enhanced friends list hook running in Blizzard's call chain
* Fixed: "Last Online" text for offline friends was being hidden

Chat

* Fixed: Clicking an item link in chat could cause an ADDON_ACTION_FORBIDDEN taint error

Summons

* Fixed: Auto-accept summons was broken and should work now

Ready Check

* Changed: Ready Check window now closes automatically after auto-accepting

Heroism Tracker

* Fixed: BL text was not reliably shown during combat and in instances
* Fixed: BL Tracker frame was intercepting mouse clicks during combat, frame is now click-through by default when locked (locked is the new default)
* Fixed: BL text did not appear when the buff came from an Evoker or a Marksmanship Hunter. Both are now detected

General

* Fixed: /rl and /nl slash commands worked even when the option was disabled
* Fixed: Mouse ring could appear as a very large circle on the minimap after visiting a housing area

**DE**

Verbesserte Freundesliste

* Behoben: Das Besuchen eines Hauses über die Kontakteliste konnte einen ADDON_ACTION_FORBIDDEN-Fehler verursachen, weil der Hook der erweiterten Freundesliste in Blizzards sicherem Aufruf lief
* Behoben: "Zuletzt online"-Text bei Offline-Freunden wurde ausgeblendet

Chat

* Behoben: Klick auf einen Item-Link im Chat konnte einen ADDON_ACTION_FORBIDDEN-Taint-Fehler verursachen

Beschwörungen

* Behoben: Auto-Beschwörung hat nicht mehr funktioniert und sollte jetzt funktionieren

Ready Check

* Geändert: Das Ready-Check-Fenster schließt sich jetzt automatisch nach dem Auto-Accept

Heldentum-Tracker

* Behoben: HT-Text wurde im Kampf nicht zuverlässig angezeigt, vor allem in Instanzen 
* Behoben: Der HT-Tracker-Frame hat Maus-Klicks im Kampf blockiert, Frame ist jetzt standardmäßig click-through wenn gesperrt (gesperrt ist jetzt der Standard)
* Behoben: HT-Text erschien nicht, wenn der Buff von einem Rufer oder Treffsicherheits-Jäger kam. Beide werden jetzt erkannt

Allgemein

* Behoben: /rl und /nl funktionierten auch wenn die Option deaktiviert war
* Behoben: Der Mausring konnte nach dem Besuchen eines Housing-Bereichs als sehr großer Kreis auf der Minimap erscheinen


## 0.9.5

**EN**

Quest

* Fixed: Auto Quest could trigger a protected VisitHouse() call when opening gossip at a housing contact, causing an ADDON_ACTION_FORBIDDEN error

**DE**

Quest

* Behoben: Auto Quest konnte beim Öffnen von Gossip an einem Housing-Kontakt einen geschützten VisitHouse()-Aufruf auslösen und einen ADDON_ACTION_FORBIDDEN-Fehler verursachen


## 0.9.4

**EN**

General
* Addon name unified to "Aklime Mod Tools" everywhere

Translation
* Addon fully bilingual (EN/DE)

Character Tracker
* Raid name translation table corrected and expanded
* Currency sorting in the Settings panel

Easy Confirm and Delete
* Two new separate checkboxes added:
* No longer type UNLEARN 
* No longer type UNDERSTOOD 
* UNLEARN was previously bundled internally under "CONFIRM", now standalone

Gear Check
* Enchant indicator for weapon slots correctly positioned (was mirrored)
* Main hand: text now appears on the left (outward), off hand: right (outward)

Prey Progress (formerly Hunt % Display)
* Module renamed: "Prey Progress in Phases" / "Jagd Fortschritt in Phasen"
* Display changed: instead of 25 / 50 / 75 / 100 % now Phase 1 / Phase 2 / Phase 3 / Phase 4

Rare Enemies
* Toggle text clarified: "Add Silver Dragon additionally to the Star" 

Miscellaneous
* Possible bug fixed: saved value for UI fade could reset itself
* Drink reminder now also active in the Housing instance
* Auto-purchase confirmation: skip option added

**DE**

Allgemein
* Addon-Name überall vereinheitlicht zu „Aklime Mod Tools"

Übersetzung
* Addon vollständig bilingual (EN/DE)

Charakter-Tracker
* Raid-Namensübersetzungstabelle korrigiert und erweitert
* Währungssortierung im Settings-Panel

Easy Confirm and Delete
* Zwei neue separate Haken ergänzt:
* Nicht mehr VERLERNEN schreiben
* Nicht mehr VERSTANDEN schreiben
* VERLERNEN war bisher intern unter „BESTÄTIGEN" versteckt, ist jetzt eigenständig

Gear Check
* Verzauberungs-Anzeige bei Waffen-Slots korrekt positioniert (war gespiegelt)
* Hauptwaffe: Text erscheint jetzt links (auswärts), Nebenwaffe: rechts (auswärts)

Prey Progress (ehemals Hunt % Display)
* Modul umbenannt: „Prey Progress in Phases" / „Jagd Fortschritt in Phasen"
* Anzeige geändert: statt 25 / 50 / 75 / 100 % jetzt Phase 1 / Phase 2 / Phase 3 / Phase 4

Seltene Gegner
* Toggle-Text präzisiert: „Add Silver Dragon additionally to the Star" / „Silbernen Drachen zusätzlich zum Stern hinzufügen"

Sonstiges
* Möglicher Bug behoben: gespeicherter Wert beim UI-Ausblenden konnte sich zurücksetzen
* Trink-Erinnerung jetzt auch in der Housing-Instanz aktiv
* Auto-Kauf Bestätigung: Skip-Option ergänzt

## 0.9.3

**EN**
- New: Lazy Ready Check, automatically confirms ready checks after a configurable delay
- New: Auto Skip Cutscene, skips in-game cutscenes and cinematics automatically
- New: Auto Quest Turn-In, automatically turns in quests with options to include dailies and exclude weeklies
- New: Colorizer global color, enable all skins at once and set a single shared color for all of them
- New: Minimap now has 6 buttons (previously 4), added Playtime and Todo List buttons
- New: Character tracker icon updated
- Overhaul: Character tracker currencies reorganized by expansion with sorting and per-currency totals across all characters (including Oath-Bound Service Medal)
- WiP: Mana warning
- WiP: Mouse effects, checkbox options removed, slider not yet implemented
- Fix: Playtime total percentage no longer fails to reach 100%
- Fix: Raid frame centering bug resolved
- Fix: Friends list favorite star now appears to the right of the name instead of being clipped by the scroll region
- Fix: Friends list separator between BattleTag and character name removed
- Fix: Chat copy window now shows the active tab name in the title
- Fix: Chat copy detects the active tab via FCFDock instead of always reading from the first visible frame
- Fix: Chat copy line click mapping corrected by setting EditBox width before inserting text
- Fix: Chat copy window now scrolls to the most recent messages on open
- Fix: Raid frame debuff type indicators (magic/poison/curse/disease) no longer overridden by Colorizer border tinting

**DE**
- Neu: Lazy Ready Check, bestätigt Ready Checks automatisch nach einer einstellbaren Verzögerung
- Neu: Auto Cutscene Skip, überspringt Ingame-Cutscenes und Cinematics automatisch
- Neu: Auto Quest Abgeben, gibt Quests automatisch ab mit Optionen für Dailies und Weekly-Ausschluss
- Neu: Colorizer Globalfarbe, alle Skins auf einmal aktivieren und eine gemeinsame Farbe für alle setzen
- Neu: Minimap hat jetzt 6 Knöpfe (vorher 4), Playtime und Todo-Liste hinzugefügt
- Neu: Icon für den Charakter-Tracker geändert
- Überarbeitung: Charakter-Tracker Währungen nach Expansion sortiert mit Gesamtsummen pro Währung über alle Charaktere (inkl. Dienstmedaille der Eidgebundenen)
- WiP: Mana-Warnung
- WiP: Mauseffekte, Haken-Optionen entfernt, Slider noch nicht umgesetzt
- Fix: Playtime Gesamt-Prozent erreicht jetzt korrekt 100%
- Fix: Bug beim Zentralisieren von Raid Frames behoben
- Fix: Favoriten-Stern in der Freundesliste erscheint jetzt rechts neben dem Namen statt vom Scroll-Bereich abgeschnitten zu werden
- Fix: Trennzeichen zwischen BattleTag und Charaktername in der Freundesliste entfernt
- Fix: Chat-Kopier-Fenster zeigt den aktiven Tab-Namen im Titel an
- Fix: Chat-Kopieren erkennt den aktiven Tab über FCFDock statt immer vom ersten sichtbaren Frame zu lesen
- Fix: Zeilen-Klick-Zuordnung im Chat-Kopier-Fenster korrigiert durch Setzen der EditBox-Breite vor dem Einfügen
- Fix: Chat-Kopier-Fenster scrollt beim Öffnen automatisch zu den neuesten Nachrichten
- Fix: Raidframe Debuff-Typ-Indikatoren (Magie/Gift/Fluch/Krankheit) werden vom Colorizer nicht mehr überschrieben

## 0.9.2

**EN**
- Fix: Addon initializes correctly after rename to AklimeModTools
- Fix: Mouse trail particles now disappear correctly after playing

**DE**
- Fix: Addon initialisiert nach Umbenennung zu AklimeModTools korrekt
- Fix: Mausspur-Partikel verschwinden nun korrekt nach dem Abspielen

## 0.9.1

**EN**
- Fix: CurseForge upload via GitHub Actions set up

**DE**
- Fix: CurseForge Upload über GitHub Actions eingerichtet

## 0.9.0

**EN**
- Initial release

**DE**
- Erste Veröffentlichung
