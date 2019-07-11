# create new folders
new-item -path D:\soft -ItemType directory -Force
New-Item -path D:\scripts -ItemType Directory -Force
New-Item -path D:\repos -ItemType Directory -Force
# download soft
Invoke-WebRequest -Uri https://notepad-plus-plus.org/repository/7.x/7.7.1/npp.7.7.1.Installer.x64.exe -OutFile D:\soft\note.exe -UseBasicParsing
Invoke-WebRequest -Uri http://az764295.vo.msecnd.net/stable/c7d83e57cd18f18026a8162d042843bda1bcf21f/VSCodeSetup-x64-1.35.1.exe -OutFile  D:\soft\vscode.exe -UseBasicParsing
Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.22.0.windows.1/Git-2.22.0-64-bit.exe -OutFile D:\soft\git.exe -UseBasicParsing
# install soft
& D:\soft\note.exe /S
& D:\soft\git.exe /VERYSILENT
& D:\soft\vscode.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode
#add VS Code configuration
Invoke-WebRequest -Uri https://github.com/sibich/publicscripts/raw/master/settings.json -OutFile D:\scripts\settings.json -UseBasicParsing
# set notepad++ variable
$PATH = [Environment]::GetEnvironmentVariable("PATH")
$note_path = "C:\Program Files\Notepad++"
[Environment]::SetEnvironmentVariable("PATH", "$PATH;$note_path", "Machine")
# test
$comp = $env:COMPUTERNAME
New-Item -name D:\scripts\test.txt -ItemType File -Value $comp
# install modules
Install-PackageProvider NuGet -Force -Confirm:$false
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Az -Repository PSGallery -Force -Confirm:$false
Install-Module PSWindowsUpdate -Repository PSGallery -Force -Confirm:$false
Get-Module -ListAvailable | Where-Object {$_.Name -like "az*"} | Out-File -FilePath D:\scripts\test.txt -Append
Get-Module -ListAvailable | Where-Object {$_.Name -like "PSWindowsUpdate"} | Out-File -FilePath D:\scripts\test.txt -Append
exit