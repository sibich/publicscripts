$Trigger= New-ScheduledTaskTrigger -AtLogOn
$STSet = New-ScheduledTaskSettingsSet -Priority 4
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Users\Administrator\Documents\winode.ps1"

Register-ScheduledTask -TaskName "MonitorGroupMembership" -Trigger $Trigger -User Administrator -Action $Action -RunLevel Highest -Settings $STSet