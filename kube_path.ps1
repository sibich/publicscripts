$PATH = [Environment]::GetEnvironmentVariable("PATH")
$kube_path = 'C:\Users\vitaly\.azure-kubectl'
[Environment]::SetEnvironmentVariable("PATH", "$PATH;$kube_path", "Machine")

$PATH = [Environment]::GetEnvironmentVariable("PATH")
$helm_path = 'C:\Users\vitaly\helm\windows-amd64'
[Environment]::SetEnvironmentVariable("PATH", "$PATH;$helm_path", "Machine")