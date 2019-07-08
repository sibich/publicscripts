# create new folders
new-item D:\soft -ItemType directory -Force
New-Item -path C:\Users\vitaly\scripts -ItemType Directory -Force
New-Item -path C:\Users\vitaly\repos -ItemType Directory -Force
# download soft
Invoke-WebRequest -Uri https://notepad-plus-plus.org/repository/7.x/7.7.1/npp.7.7.1.Installer.x64.exe -OutFile D:\soft\note.exe -UseBasicParsing
Invoke-WebRequest -Uri http://az764295.vo.msecnd.net/stable/c7d83e57cd18f18026a8162d042843bda1bcf21f/VSCodeSetup-x64-1.35.1.exe -OutFile  D:\soft\vscode.exe -UseBasicParsing
Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.22.0.windows.1/Git-2.22.0-64-bit.exe -OutFile D:\soft\git.exe -UseBasicParsing
# install soft
& D:\soft\note.exe /S
& D:\soft\git.exe /VERYSILENT
& D:\soft\vscode.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode
#add VS Code configuration
Invoke-WebRequest -Uri https://github.com/sibich/publicscripts/raw/master/settings.json -OutFile C:\Users\vitaly\scripts\settings.json -UseBasicParsing
