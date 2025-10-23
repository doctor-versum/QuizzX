@echo off
echo Installing Python dependencies...
call venv\Scripts\activate.bat
pip install -r requirements.txt
echo Dependencies installed successfully!
pause 