$connectionName = "AzureRunAsConnection"
$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName

$tenantID = $servicePrincipalConnection.TenantId
$azureServicePrincipalSecretKey = "85ba765b-9233-4f15-8a8f-4925c2eb223e"
$azureServicePrincipalClientId = "0e0a4329-7a18-46a6-a202-1f9caa232f4c"
$subscription = "6822a156-20f4-4617-94c5-8614ee7eae94"  #using Customers preprod

$passwd = ConvertTo-SecureString $azureServicePrincipalSecretKey -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($azureServicePrincipalClientId, $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenantID -WarningAction SilentlyContinue | Out-Null
Select-AzSubscription $subscription | Out-Null
#global variables
$apiVersion = '2015-08-19'
Write-Output (get-date -Format MM-dd-yyy-hh-mm)
Function new-OMSRecord {
        Param (
            [Parameter(Mandatory=$true)]
            [string] $ResourceGroupName,
            [Parameter(Mandatory=$true)]
            [string] $SearchProviderName,
            [Parameter(Mandatory=$true)]
            [string] $usage,
            [Parameter(Mandatory=$true)]
            [string] $DocumentNumber    
        )
        
        $logs = @()
    
        # create log record
        $logs += @{
            resourceGroup = $ResourceGroupName
            searchService = $SearchProviderName
            category = "storage usage"
            index = "percentage"
            usage = [int32]$usage
            DocumentsNumber = [int32]$DocumentNumber    
        }
       
        return $logs
    }

    Function new-OpsGenieAlert {
        Param (
            [Parameter(Mandatory=$true)]
            [string] $ResourceGroupName,
            [Parameter(Mandatory=$true)]
            [string] $SearchName,
            [Parameter(Mandatory=$true)]
            [string] $subscription,
            [Parameter(Mandatory=$true)]
            [string] $subID,
            [Parameter(Mandatory=$true)]
            [string] $opsgeniekey
        )
    $authkey = "GenieKey " + $opsgeniekey
    $RestAPIHeader = @{"Authorization" = "$authkey"; "Content-Type" = " application/json"}
    $message = "[Azure OMS] " + $searchname + " Search service storage usage reached 90%"
    $alias = $searchname + " storage usage"
        
    $Payload = @"
        {
        "message": "$message",
        "alias": "$alias",
        "description":"Start time:\nEnd time:\nTook: secs.\nSubscription: $subscription\nResource group: $ResourceGroupName\nResource: $searchname",
        "tags": ["Customer: $subscription","Resource: $searchname","Service Name: Managed Cloud","Tenant type: Customers"],
        "details":{"alert source": "Azure Automation Account","ResourceLink": "<a target=\`"_blank\`" href=\`"https://portal.azure.com/#@sitecore.com/resource/subscriptions/$subID/resourceGroups/$ResourceGroupName/providers/Microsoft.Search/searchServices/$searchname\`">Go to resource</a>"},
        "entity":"An example entity",
        "priority":"P4",
        "source":"AzureOMS"
    }
"@
        $AlertUrl = "https://api.eu.opsgenie.com/v2/alerts/"
        $Alert = Invoke-RestMethod -Method Post -Header $RestAPIHeader -Uri $AlertUrl -Body $Payload
        return $Alert
    }
#sitecore service principal
$appid = "273914d3-2399-4a3b-bfbc-8e44d1f3d3b2"
$pscredential = New-Object System.Management.Automation.PSCredential($appid,`
                (Get-AzKeyVaultSecret -VaultName ppcorekeyvault -Name SitecoreSupportAccessSP).SecretValue)
$opsgeniekey = (Get-AzKeyVaultSecret -VaultName ppcorekeyvault -Name OpsGenieApiKey).SecretValueText
Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenantId -WarningAction SilentlyContinue | Out-Null

### for tests
$testsubscription = "6822a156-20f4-4617-94c5-8614ee7eae94"
$testrg = "mc-f6f5d4e8-1bfb-4abe-9b19-d8316d66a90e"


$subs = Get-AzSubscription -TenantId $tenantID | Where-Object {$_.subscriptionID -eq $testsubscription}
Foreach($sub in $subs){
            
        $subID = $sub.ID
        $subscription = $sub.Name
        Select-AzSubscription -SubscriptionObject $sub | Out-Null
        $resourcegroups  = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -eq $testrg}
        foreach($el in $resourcegroups){
            $rg = $el.ResourceGroupName
            $searchservice = get-azsearchservice -ResourceGroupName $rg
            if ($searchservice){
                $searchname = $searchservice.Name
                $searchId = $searchservice.Id
                $searchpc = $searchservice.PartitionCount
                $resDocMax =  15000000 * $searchpc
                $resDocMax22million =  22000000 * $searchpc
                $quota = 26843545600 * $searchpc
                
                ("Subscription: " + $subscription)
                ("Resource group: " + $rg)            
                ("Search Service: " + $searchname)
                ("Storage quota is " + $quota)

                # Get Admin Key for search service
                $resapikey = (Invoke-AzResourceAction -Action listAdminKeys -ResourceId $searchId  -ApiVersion $apiversion -Force).PrimaryKey
                            
                # Get index names for search service  
                $URI01 = "https://$searchname.search.windows.net/indexes?api-version=2016-09-01-Preview"
                $response01 = Invoke-RestMethod -Method Get -Uri $URI01 -Headers @{"api-key" = "$resapikey"}
                $indexname = $response01 |  select-object -ExpandProperty value |  Select-Object  name
                 
                # Count the number of documents in each azure search service index, and then calculate the total number of documents in each azure search service"
                $totaldocumentcount = 0
                $totalstoragesize = 0

                foreach ($el in $indexname) {
                        $URI02 = "https://$($searchname).search.windows.net/indexes/$($el.name)/stats?api-version=2016-09-01-Preview"
                        $response02 = Invoke-RestMethod -Method Get -Uri $URI02 -Headers @{"api-key" = "$resapikey"}
                        
                        $onedocumentCount = ($response02 | Select-Object -Property documentCount -ExpandProperty documentCount | Format-List | Out-String).Trim()
                        $onestoragesize= ($response02 | Select-Object -Property storageSize -ExpandProperty storageSize | Format-List | Out-String).Trim()
                        #write-host  """$($el.name)""" " Details:"
                        #write-host ""($response02 | Select-Object -Property documentCount | Format-List | Out-String).Trim()
                        #write-host ""($response02 | Select-Object -Property storageSize | Format-List | Out-String).Trim()
                        #write-host ""
                                
                        $totaldocumentcount  = $totaldocumentcount + $onedocumentCount
                        $totalstoragesize = $totalstoragesize + $onestoragesize
                        
                      
                        }
                
                $mil22 = @("635986478408745", "635772407559414", "635974613628329", "635811725354725", "636022831245060", "635810426703869", "635957326894814", "635902053966178", "635768929950750", "635850981819349", "635804244152207", "635830195212715")
                                                        
                $percentage = 0.9 * $resDocMax
                $percentage22million = 0.9 * $resDocMax22million
                
                #Check if the azure search service exists in 22million.csv file which comprises the list of services with 22 million threshold.
                if ($searchname -in $mil22)
                { 
                        $resDocMax =  22000000 * $searchpc
                        $percentage = 0.9 * $resDocMax
                }
                
               
                ##Check if Search Service has unlimited document count and exclude it from alerts
                $URI03 = "https://$searchname.search.windows.net/servicestats?api-version=2016-09-01"
                $response03 = Invoke-RestMethod -Method Get -Uri $URI03 -Headers @{"api-key" = "$resapikey"; "Content-Type" = " application/json" ; 'Accept' = 'application/json'}
                $quota01 = ($response03 | Select-Object -ExpandProperty counters | Select-Object -ExpandProperty documentCount | Select-Object -ExpandProperty quota | Format-List | Out-String).Trim()
                If([string]::IsNullOrEmpty($Quota01) -eq $true)
                    {
                        $output= "$searchname `n" + "has unlimited document count"
                        $percentage = $resDocMax + $totaldocumentcount
                        $output                        
                    }
                
                $usage = $totalstoragesize * 100 / $quota
                $usage = 91
                ("Storage usage is: " + $usage)
                if($usage -ge 90){
                "Alert will be created"
                new-OpsGenieAlert -subscription $subscription -ResourceGroupName $rg -SearchName $searchname -opsgeniekey $opsgeniekey -subID $subID
                }
                
            }
        }
}
