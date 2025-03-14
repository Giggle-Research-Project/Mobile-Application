@echo off
:: Run the Python script
python lib\config\getip.py

:: Then run the Flutter app
flutter run

:: Pause the script to view any output before it closes (optional)
pause
