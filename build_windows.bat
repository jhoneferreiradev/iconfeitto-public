@echo off
echo Iniciando execucao
flutter build windows --release && start build\windows\x64\runner\Release

echo Build finalizado com sucesso
pause