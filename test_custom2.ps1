# log file
$logfile = "D:\setup.log"
write-output (get-date -Format yyyy-MM-dd-hh-mm-ss)"Configuration was started" | Out-File -FilePath $logfile
# create new folders
new-item -path D:\soft -ItemType directory -Force
New-Item -path D:\scripts -ItemType Directory -Force
New-Item -path D:\repos -ItemType Directory -Force
write-output (get-date -Format yyyy-MM-dd-hh-mm-ss)"Folders were created:" | Out-File -FilePath $logfile -Append
Get-ChildItem -Path "D:\" -directory | Out-File -FilePath $logfile -Append

# download soft
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri http://download.notepad-plus-plus.org/repository/7.x/7.8/npp.7.8.Installer.x64.exe -OutFile D:\soft\note.exe -UseBasicParsing
Invoke-WebRequest -Uri http://az764295.vo.msecnd.net/stable/c7d83e57cd18f18026a8162d042843bda1bcf21f/VSCodeSetup-x64-1.35.1.exe -OutFile  D:\soft\vscode.exe -UseBasicParsing
Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.23.0.windows.1/Git-2.23.0-64-bit.exe -OutFile D:\soft\git.exe -UseBasicParsing
Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/53f250a1-318f-4350-8bda-3c6e49f40e76/e8cbbd98b08edd6222125268166cfc43/dotnet-sdk-3.0.100-win-x64.exe -OutFile D:\soft\dotnet.exe -UseBasicParsing
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile D:\soft\AzureCLI.msi -UseBasicParsing

# install soft
& D:\soft\note.exe /S
& D:\soft\git.exe /VERYSILENT
& D:\soft\vscode.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode
& D:\soft\dotnet.exe /QUIET

start-sleep -Seconds 240

Start-Process msiexec.exe -Wait -ArgumentList '/I D:\soft\AzureCLI.msi /quiet'
Start-Sleep -Seconds 60

write-output (get-date -Format yyyy-MM-dd-hh-mm-ss)"Software was installed:" | Out-File -FilePath $logfile -Append
Get-ChildItem 'C:\Program Files\Notepad++\' -Name notepad++.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files\Microsoft VS Code\" -Name Code.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files\Git\bin\" -Name git.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files\dotnet\" -Name dotnet.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\" -Name az.cmd | Out-File $logfile -Append

#add VS Code configuration
Invoke-WebRequest -Uri https://raw.githubusercontent.com/sibich/publicscripts/master/settings.json -OutFile D:\scripts\settings.json -UseBasicParsing

# set notepad++ variable
$PATH = [Environment]::GetEnvironmentVariable("PATH")
$note_path = "C:\Program Files\Notepad++"
$dotnet_path = "C:\Program Files\dotnet"
$git_path = "C:\Program Files\Git\bin"
$code_path = "C:\Program Files\Microsoft VS Code"
$az_path = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
[Environment]::SetEnvironmentVariable("PATH", "$PATH;$note_path;$git_path;$az_path;$dotnet_path;$code_path", "Machine")

# install modules
Install-PackageProvider NuGet -Force -Confirm:$false
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module AzureRM -Repository PSGallery -Force -Confirm:$false

# check installation
write-output (get-date -Format yyyy-MM-dd-hh-mm-ss)"Modules and features were installed:" | Out-File -FilePath $logfile -Append
Get-Module -ListAvailable | Where-Object {$_.Name -like "az*"} | Out-File -FilePath $logfile -Append

# get some data
$PSVersionTable.PSVersion | Out-File -FilePath $logfile -Append

Write-Output (get-date -Format yyyy-MM-dd-hh-mm-ss)"Configuration was completed" | Out-File -FilePath $logfile -Append
exit