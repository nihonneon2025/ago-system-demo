@echo off
chcp 65001 > nul
echo AGO SYSTEM MANAGER を起動しています...
cd /d %~dp0
start http://localhost:8080
python -m http.server 8080
