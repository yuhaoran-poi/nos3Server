@echo off
set PYTHONOPTIMIZE=1

pyinstaller --noconfirm --clean --onefile ^
  --name "ConfigTool" ^
  --icon "config_icon.ico" ^
  --hidden-import "openpyxl.cell._writer openpyxl.worksheet._reader" ^
  --hidden-import "jinja2.ext" ^
  --runtime-tmpdir "." ^
  config_converte.py

pause