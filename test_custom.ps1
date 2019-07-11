# log file
$logfile = "D:\setup.log"

# create new folders
new-item -path D:\soft -ItemType directory -Force
New-Item -path D:\scripts -ItemType Directory -Force
New-Item -path D:\repos -ItemType Directory -Force
Get-ChildItem -Path "D:\" | Out-File $logfile

# download soft
Invoke-WebRequest -Uri https://notepad-plus-plus.org/repository/7.x/7.7.1/npp.7.7.1.Installer.x64.exe -OutFile D:\soft\note.exe -UseBasicParsing
Invoke-WebRequest -Uri http://az764295.vo.msecnd.net/stable/c7d83e57cd18f18026a8162d042843bda1bcf21f/VSCodeSetup-x64-1.35.1.exe -OutFile  D:\soft\vscode.exe -UseBasicParsing
Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.22.0.windows.1/Git-2.22.0-64-bit.exe -OutFile D:\soft\git.exe -UseBasicParsing

# install soft
& D:\soft\note.exe /S
& D:\soft\git.exe /VERYSILENT
& D:\soft\vscode.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode

Get-ChildItem 'C:\Program Files\Notepad++\' -Name notepad++.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files\Microsoft VS Code\" -Name Code.exe | Out-File $logfile -Append

#add VS Code configuration
Invoke-WebRequest -Uri https://github.com/sibich/publicscripts/raw/master/settings.json -OutFile D:\scripts\settings.json -UseBasicParsing

# set notepad++ variable
$PATH = [Environment]::GetEnvironmentVariable("PATH")
$note_path = "C:\Program Files\Notepad++"
[Environment]::SetEnvironmentVariable("PATH", "$PATH;$note_path", "Machine")

# install modules
Install-PackageProvider NuGet -Force -Confirm:$false
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Az -Repository PSGallery -Force -Confirm:$false
Install-Module PSWindowsUpdate -Repository PSGallery -Force -Confirm:$false
# check installation
Get-Module -ListAvailable | Where-Object {$_.Name -like "az*"} | Out-File -FilePath $logfile -Append
Get-Module -ListAvailable | Where-Object {$_.Name -like "PSWindowsUpdate"} | Out-File -FilePath $logfile -Append
Get-WUList -AcceptAll | Out-File -FilePath $logfile -Append
$PSVersionTable.PSVersion | Out-File -FilePath $logfile -Append
# git config
& 'C:\Program Files\Git\cmd\git.exe' config --global user.name "Vitaly Sibichenkov"
& 'C:\Program Files\Git\cmd\git.exe' config --global user.email "sibich.v@gmail.com"
& 'C:\Program Files\Git\cmd\git.exe' config --global core.editor notepad++
& 'C:\Program Files\Git\cmd\git.exe' config --global color.ui "auto"
# install updates

Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false
Get-WUInstall -MicrosoftUpdate -AcceptAll -Download -Install -AutoReboot -Confirm:$false

exit