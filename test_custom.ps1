﻿# log file
$logfile = "D:\setup.log"

# create new folders
new-item -path D:\soft -ItemType directory -Force
New-Item -path D:\scripts -ItemType Directory -Force
New-Item -path D:\repos -ItemType Directory -Force
Get-ChildItem -Path "D:\" | Out-File $logfile

# download soft
Invoke-WebRequest -Uri http://download.notepad-plus-plus.org/repository/7.x/7.8/npp.7.8.Installer.x64.exe -OutFile D:\soft\note.exe -UseBasicParsing
Invoke-WebRequest -Uri http://az764295.vo.msecnd.net/stable/c7d83e57cd18f18026a8162d042843bda1bcf21f/VSCodeSetup-x64-1.35.1.exe -OutFile  D:\soft\vscode.exe -UseBasicParsing
Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.23.0.windows.1/Git-2.23.0-64-bit.exe -OutFile D:\soft\git.exe -UseBasicParsing
Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/53f250a1-318f-4350-8bda-3c6e49f40e76/e8cbbd98b08edd6222125268166cfc43/dotnet-sdk-3.0.100-win-x64.exe -OutFile D:\soft\dotnet.exe -UseBasicParsing

# install soft
& D:\soft\note.exe /S
& D:\soft\git.exe /VERYSILENT
& D:\soft\vscode.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode
& D:\soft\dotnet.exe /QUIET
start-sleep -Seconds 300
Get-ChildItem 'C:\Program Files\Notepad++\' -Name notepad++.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files\Microsoft VS Code\" -Name Code.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files\Git\bin\" -Name git.exe | Out-File $logfile -Append
Get-ChildItem "C:\Program Files\dotnet\" -Name dotnet.exe | Out-File $logfile -Append

#add VS Code configuration
Invoke-WebRequest -Uri https://raw.githubusercontent.com/sibich/publicscripts/master/settings.json -OutFile D:\scripts\settings.json -UseBasicParsing

# set notepad++ variable
$PATH = [Environment]::GetEnvironmentVariable("PATH")
$note_path = "C:\Program Files\Notepad++"
[Environment]::SetEnvironmentVariable("PATH", "$PATH;$note_path", "Machine")

# install modules
Install-PackageProvider NuGet -Force -Confirm:$false
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Az -Repository PSGallery -Force -Confirm:$false
Install-Module PSWindowsUpdate -Repository PSGallery -Force -Confirm:$false

# installing docker
Install-WindowsFeature Hyper-V -Force -Confirm:$false
Install-WindowsFeature Containers -Force -Confirm:$false
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -norestart
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force -Confirm:$false
Install-Package -Name docker -ProviderName DockerMsftProvider -Force -Confirm:$false

start-sleep -Seconds 300
Get-WindowsFeature -Name containers | Out-File $logfile -Append
Get-WindowsFeature -Name Hyper-V | Out-File $logfile -Append

# copy docker config file
Invoke-WebRequest -Uri https://raw.githubusercontent.com/sibich/publicscripts/master/daemon.json -OutFile C:\Programdata\docker\config\daemon.json -UseBasicParsing

# check installation
Get-Module -ListAvailable | Where-Object {$_.Name -like "az*"} | Out-File -FilePath $logfile -Append
Get-Module -ListAvailable | Where-Object {$_.Name -like "PSWindowsUpdate"} | Out-File -FilePath $logfile -Append

# get some data
Get-WUList -AcceptAll | Out-File -FilePath $logfile -Append
$PSVersionTable.PSVersion | Out-File -FilePath $logfile -Append

# initialize data disk
$disks = Get-Disk | Where partitionstyle -eq 'raw' | sort number

    $letters = 70..89 | ForEach-Object { [char]$_ }
    $count = 0
    $labels = "data1","data2"

    foreach ($disk in $disks) {
        $driveLetter = $letters[$count].ToString()
        $disk | 
        Initialize-Disk -PartitionStyle MBR -PassThru |
        New-Partition -UseMaximumSize -DriveLetter $driveLetter |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel $labels[$count] -Confirm:$false -Force
	$count++
    }

#start docker
restart-Service Docker

# install updates
Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false
Get-WUInstall -MicrosoftUpdate -AcceptAll -Download -Install -AutoReboot -Confirm:$false

exit