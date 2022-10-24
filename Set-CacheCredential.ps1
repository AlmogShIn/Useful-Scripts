<#
    .SYNOPSIS
    Setting credential into thed cache
    .DESCRIPTION
    Setting credential into thed cache in order to use it while the session is runnung
    .INPUTS
    $credential 
    .OUTPUTS
    $msg1: massage status(Sucsess / faild to set + exception msg)
    .EXAMPLE
    Set-CacheCredential -credential $userCredential
#>
function Set-CacheCredential {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    Param (
        [PSCredential] $userCredential
    )
    if (-not $userCredential) { 
        $userCredential = (Get-Credential) 
    }

    try {
        Set-Variable -Scope Global -name "CachedValRebulid-$($userCredential.UserName)" -Value $userCredential
    }
    catch {
        Write-Warning ("Failed to set varible" + $_.Exception)
    }
}