# QuizzX
### Das einzigartige Echtzeit-Quizshow-Erlebnis für bis zu 4 Teams

## Inhalt
- [Überblick](#überblick)
- [Installation](#installation)
- [Nutzung](#nutzung)
- [Lizenz](#lizenz)

## Überblick

### Server auf Windows, Client in Flutter

Der Server von QuizzX läuft einfach auf einem Windows-Computer, sodass du keine komplexe Server-Infrastruktur benötigst. Die Client-App ist plattformübergreifend und mit Flutter entwickelt, was bedeutet, dass sie sowohl auf Android als auch auf vielen anderen Plattformen läuft. So kannst du QuizzX überall und auf nahezu jedem Gerät verwenden. Die einfache Handhabung macht es zu einer schnellen Lösung für jede Veranstaltung.

![](/docs/images/team_blue.jpg)

### 100% modulare konfiguration

Die Konfiguration von QuizzX erfolgt vollständig über eine JSONC-Datei, was dir maximale Flexibilität gibt. Du kannst neue Fragen, Themen und Spielmodi problemlos hinzufügen, ohne den Code ändern zu müssen. Alles ist modular, sodass du die App nach deinen eigenen Vorstellungen gestalten kannst. Egal, ob du ein Quiz mit Standardfragen oder ein benutzerdefiniertes Event mit eigenen Regeln erstellen möchtest, QuizzX passt sich an.

![](/docs/images/config.png)

### Administrator CLients

QuizzX bietet eine umfassende Administrator-Oberfläche, mit der du das Spiel jederzeit steuern kannst. Verwalte Teams, steuere die Timer und wechsle dynamisch zwischen verschiedenen Spielansichten.

![](/docs/images/master.png)

### API & WebSocket für Echtzeit-Daten

Mit der QuizzX API kannst du jederzeit auf die wichtigsten Daten zugreifen: die Punkte aller Teams, die Anzahl der verbundenen Geräte und das aktuell aktive Team. Über den WebSocket wirst du in Echtzeit über das Spielgeschehen informiert. Egal, ob du eine Weboberfläche für Zuschauer entwickeln oder die Daten extern nutzen möchtest – die API stellt dir alles zur Verfügung, was du benötigst. Diese Funktion bringt das Spiel auf die nächste Stufe und sorgt für ein noch intensiveres Erlebnis.

![](/docs/images/homescreen.png)

### Interaktive Punkteanzeige

Die QuizzX-App enthält eine dynamische Punkteanzeige, die die Ergebnisse aller Teams in Echtzeit anzeigt. Du kannst bis zu vier Teams verwalten: Rot, Blau, Grün und Gelb. Die Anzeige zeigt automatisch nur die Teams an, die mindestens ein verbundenes Gerät haben. Über die Web-Konsole kannst du die Sichtbarkeit von Teams manuell steuern, sodass du die Anzeige für verschiedene Teams nach Bedarf ein- oder ausblenden kannst.

![](/docs/images/points.png)

### Verschiedene Slide-Typen

Die QuizzX-App bietet verschiedene Arten von Sliden, um das Spiel noch spannender zu gestalten. Du kannst Text-Slides, Timer-Slides und Buzzer-Slides verwenden, um die Teilnehmer zu aktivieren und das Spiel voranzutreiben. Für visuelle Highlights kannst du auch Bild-Slides hinzufügen, die entweder aus dem Internet geladen oder lokal auf dem Server gehostet werden. Das gibt dir die Freiheit, das Spiel mit unterschiedlichen Medien und Inhalten zu gestalten und auf die Bedürfnisse deines Events anzupassen.

![](/docs/images/team_red.jpg)

## Installation

### Android Client
1. Laden Sie die `quizzx_android.apk` aus den [letzten Releases](https://github.com/doctor-versum/quizzx/releases/tag/stable) auf Ihr Mobilgerät herunter (oder auf einem PC und installieren Sie es via ADB oder übertragen Sie die Datei via FTP, dies ist jedoch komplizierter).
2. Öffnen Sie den Datei-Explorer (z.B. „Files by Google“ auf Google Pixel) und navigieren Sie zum Downloads-Ordner.
3. Tippen Sie auf die APK-Datei.
4. Wählen Sie „Installieren“.
5. Möglicherweise müssen Sie den Datei-Explorer in den Einstellungen als vertrauenswürdige Quelle für APKs festlegen.
6. Android könnte die APK auf Viren scannen (da sie unsigniert ist).
7. Nach der Installation funktioniert die App wie jede andere.

### Windows Server
1. Laden Sie die `quizzx_server_win.zip` aus den [letzten Releases](https://github.com/doctor-versum/quizzx/releases/tag/stable) herunter.
2. Entpacken Sie die ZIP-Datei an einem Ort Ihrer Wahl.
3. Doppelklicken Sie auf `install_dependencies.bat`. Dies erstellt ein virtuelles Python-Environment und installiert die benötigten Bibliotheken.
4. Zum Starten des Servers doppelklicken Sie einfach auf `start.bat`.

## Nutzung

### Android Client
1. Starten Sie die App und geben Sie die IP-Adresse und den Port des Servers ein. Die IP-Adresse finden Sie mit dem Befehl `ipconfig` unter Ihrem Netzwerkadapter in der Eingabeaufforderung oder in den Einstellungen. Der Standard-Port des Servers ist 8765.
   - Beispiel: `192.168.178.149:8765` (dies ist eine lokale IP-Adresse, bitte teilen Sie keine öffentlichen IPs mit anderen).
2. Wählen Sie die Teamfarbe für dieses Gerät oder „Master“ aus.
3. Wenn der Server läuft, sollte er nun verbunden sein.

### Windows Server
1. Erstellen Sie eine `config.jsonc` im gleichen Verzeichnis wie die `host.py` oder benennen Sie die `demo-config.jsonc` um. Ressourcen zum Erstellen einer eigenen Config finden Sie [hier (WIP)](/wiki/configfile).
2. Starten Sie nun einfach `start.bat`.

## Lizenz

Die Software wird unter der [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/) zur Verfügung gestellt.

Konfigurationen der Software, die online geteilt werden, müssen unter der [Creative Commons NonCommercial-ShareAlike 4.0 International License (CC NC-SA 4.0)](https://creativecommons.org/licenses/nc-sa/4.0/) oder der [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/) zur Verfügung gestellt werden.

Die **Website** und ihre **Texte** sind unter der [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/) lizenziert, **mit der Einschränkung, dass die Texte nur im Kontext von „QuizzX“ verwendet werden dürfen**. Sie dürfen nicht in eigenständigen Projekten verwendet werden, es sei denn, es wird ein klarer Link zum [QuizzX Repository](https://github.com/doctor-versum/quizzx) bereitgestellt. Änderungen an den Texten müssen ebenfalls unter der gleichen Lizenz stehen.
