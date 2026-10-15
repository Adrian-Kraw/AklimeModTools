## 1.4.3

**EN**

Auto Repair

* Fixed: The chat messages after repairing were always German, even on an English client. They now follow the language of the game client.
* Fixed: Repairing at a vendor threw a Lua error when the message with the repair costs was printed. The repair itself worked. The message now shows the costs again.

Center Raid Frames

* Fixed: After a reload or a spec change the raid frames were no longer centered, even with the feature switched on. The game puts them back to their Edit Mode position in both cases. The frames kept their size, so the addon assumed they were still centered and did nothing. It now notices when the game moves the frames and centers them again.

Drink Reminder

* Fixed: The "Got it!" button could end up hidden behind other windows, for example a tooltip, so you had to close them to click it. The button now sits on the same layer as the reminder and always stays on top.

Character Tracker

* Changed: The Great Vault shows the level of every slot, for example the key level, the raid difficulty or the delve tier. Hovering a cell lists the three slots with the item level of their reward.
* Changed: A new row shows the Mythic keystone each character carries. It disappears at the weekly reset, together with the vault progress.
* Changed: New look with section bars, a divider between the labels and the characters and icons next to the raid names.

Settings Window

* Changed: The Interface category is split into Character and Portrait, Combat and Minimap.
* Changed: All color customizations moved from Interface into the new category Color Customization.
* Changed: Quality of Life is split into Chat, Social, Group Activities, Merchant, Blizzard Bug Fixes, Combat, Quest, Miscellaneous and Micro Menu. Chat Interaction is now called Copy Chat.
* Changed: The Weekly Vault entry no longer has a checkbox, it only opens the vault.
* Changed: Color Customization uses the German names on a German client, for example Kalender instead of Calendar.

Ready Check

* Fixed: A Not Ready you clicked yourself was overridden by the automatic Ready when the countdown ended. The addon now leaves your decision alone.

**DE**

Auto Repair

* Behoben: Die Chatnachrichten nach dem Reparieren waren immer deutsch, auch auf einem englischen Client. Sie folgen jetzt der Sprache des Spielclients.
* Behoben: Beim Reparieren beim Händler trat ein Lua-Fehler auf, als die Meldung mit den Reparaturkosten ausgegeben wurde. Die Reparatur selbst hat funktioniert. Die Meldung zeigt die Kosten jetzt wieder an.

Gruppenrahmen zentrieren

* Behoben: Nach einem Reload oder einem Spezialisierungswechsel waren die Gruppenrahmen nicht mehr zentriert, obwohl die Funktion an war. Das Spiel setzt sie in beiden Fällen an ihre Position aus dem Bearbeitungsmodus zurück. Die Größe der Rahmen blieb gleich, deshalb hielt das Addon sie weiter für zentriert und tat nichts. Es merkt jetzt, wenn das Spiel die Rahmen verschiebt, und zentriert sie erneut.

Trinkerinnerung

* Behoben: Der Knopf "Alles klar!" konnte hinter anderen Fenstern verschwinden, zum Beispiel hinter einem Tooltip, sodass du sie schließen musstest, um ihn anzuklicken. Der Knopf liegt jetzt auf derselben Ebene wie die Erinnerung und bleibt immer oben.

Charakter-Tracker

* Geändert: Die Große Schatzkammer zeigt die Stufe jedes Platzes, zum Beispiel die Schlüsselstufe, die Schlachtzug-Schwierigkeit oder die Stufe der Tiefen. Beim Überfahren einer Zelle stehen die drei Plätze mit der Gegenstandsstufe ihrer Belohnung im Tooltip.
* Geändert: Eine neue Zeile zeigt den Mythic-Schlüsselstein, den jeder Charakter trägt. Er verschwindet beim wöchentlichen Reset, genau wie der Fortschritt der Schatzkammer.
* Geändert: Neue Optik mit Abschnittsbalken, einer Trennlinie zwischen Beschriftung und Charakteren und Symbolen neben den Schlachtzugnamen.

Einstellungsfenster

* Geändert: Die Kategorie Interface ist in Charakter und Portrait, Kampf und Minimap unterteilt.
* Geändert: Alle farblichen Anpassungen sind aus Interface in die neue Kategorie Farbliche Anpassungen gewandert.
* Geändert: Quality of Life ist in Chat, Social, Gruppenaktivitäten, Händler, Blizzard Bugfixes, Kampf, Quest, Sonstiges und Micromenüleiste unterteilt. Chat Interaktion heißt jetzt Chat kopieren.
* Geändert: Der Eintrag Wöchentliche Schatzkammer hat keinen Haken mehr, er öffnet nur noch die Schatzkammer.
* Geändert: Die farblichen Anpassungen zeigen auf einem deutschen Client die deutschen Namen, zum Beispiel Kalender statt Calendar.

Bereitschaftsabfrage

* Behoben: Ein selbst geklicktes Nicht bereit wurde vom automatischen Bereit überschrieben, wenn der Countdown ablief. Das Addon lässt deine Entscheidung jetzt in Ruhe.
