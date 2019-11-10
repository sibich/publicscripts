$PATH = [Environment]::GetEnvironmentVariable("PATH")
$kube_path = 'C:\Users\vitaly\.azure-kubectl'
[Environment]::SetEnvironmentVariable("PATH", "$PATH;$kube_path", "Machine")