#Connect to Azure
Set-AzureAutomationEnv -Environment Integration
#Connect to ServiceNow Cloud
Write-Output "ServiceNow Cloud authentication..."
$serviceNowTokenUrl = Get-AutomationVariable -Name Automation-ServiceNow-TokenURL
$serviceNow_URL = Get-AutomationVariable -Name Automation-ServiceNow-URL
$serviceNowClientCred = Get-AutomationPSCredential -Name Automation-ServiceNow-Credential -ErrorAction SilentlyContinue
$isAuthToSN = Set-ServiceNowAuth -ServiceNowUrl $serviceNow_URL -TokenUrl $serviceNowTokenUrl -ClientCredentials $serviceNowClientCred 
if ($isAuthToSN) {
    Write-Output "ServiceNow Cloud has authenticated"
}
else {
    Write-Error "ServiceNow Cloud has NOT connected.."
}

#Get all servers in the env'
$machines = Get-DatabaseData -dbInstance haisqlc165.ger.corp.intel.com -database muluserdata -port 3181 -query "select hostname from validation" -integratedSecurity
$machines = $machines[0..10]
#$machines[0].hostname | Get-ECRecentUser

Add-Content -Path PrimOnwerServerName.csv -Value 'Server Name, Primary Customer, Customer Email'

foreach ($server in $machines.hostname) {
    # ServiceNow entry
    $serverObject = Get-ServiceNowServer -ServerName $server
    # Set primary customer
    $primaryCustomerIDSID = $serverObject.PrimaryCustomerContactIDSID
    $CustomerEmail = Get-ADObject -LDAPFilter "(&(samAccountName=$primaryCustomerIDSID)(intelflags=1))" -Server 'corp:3268' -Properties mail -ErrorAction SilentlyContinue

    Add-Content -Path .\PrimOnwerServerName.csv -Value ($server, $primaryCustomerIDSID, $CustomerEmail)
}
    
