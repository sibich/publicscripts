$logfile = "C:\Users\Administrator\Documents\log.txt"
$proc = Get-service | Where-Object {$_.Name -ilike "*docker*"}
Write-Output (get-date -Format MM-dd-yyy-hh-mm) | Out-File -FilePath $logfile
foreach($svc in $proc)
{
    if($svc.status -ne "running"){
        ($svc.Name + "Service is not running") | Out-File -FilePath $logfile -Append
        $svc | Start-Service
        $svc.WaitForStatus('Running','00:00:20')
        start-sleep 10
        start-service rancher-wins
        start-sleep 10
        nssm start kubelet
        start-sleep 10
    }
    ($svc.status) | Out-File -FilePath $logfile -Append
    
}

# Create host network to allow kubelet to schedule hostNetwork pods
("Creating Docker host network") | Out-File -FilePath $logfile -Append

docker network create -d nat host

#clean up
start-sleep 30
docker rm $(docker ps -a -f status=exited -q)

