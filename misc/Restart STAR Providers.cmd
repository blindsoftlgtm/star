@echo off
title Restart STAR Voice Providers
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0restart-star-providers.ps1"
