@echo off
REM Prüfen, ob das Virtual Environment (venv) existiert
IF NOT EXIST "venv\Scripts\activate.bat" (
    echo Virtual Environment existiert nicht. Erstelle ein neues...
    python -m venv venv
)

REM Überprüfen, ob PowerShell verwendet wird
REM Wenn PowerShell verwendet wird, aktivieren wir mit Activate.ps1
IF EXIST "venv\Scripts\Activate.ps1" (
    echo Aktivieren des Virtual Environments mit PowerShell...
    powershell -ExecutionPolicy Bypass -File venv\Scripts\Activate.ps1
) ELSE (
    REM Ansonsten Standard: Aktivierung für cmd
    echo Aktivieren des Virtual Environments mit CMD...
    call venv\Scripts\activate.bat
)

REM Installieren der Anforderungen aus der requirements.txt
echo Installiere Pakete aus requirements.txt...
pip install -r requirements.txt

REM Fertig
echo Installation abgeschlossen!
pause
