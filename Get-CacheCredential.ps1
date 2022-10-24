<#
    .SYNOPSIS
    Setting credential into thed cache
    .DESCRIPTION
    Setting credential into thed cache in order to use it while the session is runnung
    .INPUTS
    $credential 
    .OUTPUTS
    $msg1: one word status
    .EXAMPLE
    Set-CacheCredential -credential $userCredential 
    Set-CacheCredential

#>
function Get-CacheCredential {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    Param (
        [PSCredential] $userCredential
    )
    $RetriveUserCres = $False

    if ($userCredential) {
        try {
            #Trying to retrive the password for the user name 
            $cachedResults = Get-variable "CachedValRebulid-$($userCredential.UserName)*" -Scope Global 

            #If not manage to find, retrive from user
            if (-not $cachedResults) { Set-CacheCredential -userCredential $userCredential }
        }
        catch {
            if ($_.Exception.Message -like "Cannot find a variable with the name") {
                $RetriveUserCres = $True
            }
            else {
                throw $_.Exception.Message
            }
        }
    }
    else {
        $cachedResults = Get-Variable "CachedValRebulid-*" -Scope Global 
        if (-not $cachedResults) { $RetriveUserCres = $True }
    }

    if ($RetriveUserCres) {
        $userCredential = (Get-Credential) 
        Set-CacheCredential -userCredential $userCredential

        
    } 
    return (Get-Variable "CachedValRebulid-$($userCredential.UserName)*" -Scope Global).value
}