<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER Environment

    .EXAMPLE
        PS C:\>
    .NOTES
        Additional information about the function.
#>
function Send-EmailFromSortFile {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    param()
    Write-Log -Level INFO -Message 'Start sending emails'

    $sortedCsvFile = Import-Csv -Path $Global:SortedServersNamePath
    #Add column for EmailSentAt
    $sortedCsvFile | Select-Object *, @{n = "EmailSentAt"; e = { "" } } | Export-Csv $Global:SortedServersNamePath -NoTypeInformation

    $sortedCsvFile = Import-Csv -Path $Global:SortedServersNamePath

    #Get the email data template by the relevant CI ID
    $EmailData = Get-EmailBodyData -CI_ID $Global:CI_ID

    #Count the cuurent row
    $Index = 0
    $CountEmailHasSent = 0
    #The number of lines in the file represents the number of emails to send.
    $TotalEmailToSent = (Get-Content $Global:SortedServersNamePath).Length - 1
    
    foreach ( $row In $sortedCsvFile) {
        $EmailObject = New-SendMailObject -Template General

        $EmailObject.Subject = "Action Required For Your Server"
        $EmailObject.Title = $EmailData.Title

        $EmailBody = $EmailData.BodyMsgPart1
        $EmailBody += $sortedCsvFile[$Index].serverName
        $EmailBody += $EmailData.BodyMsgPart2

        $EmailObject.Content = $EmailBody

        $EmailObject.To = $row.CustomerEmail
        $EmailObject.CC = 'Almog.shtaigmann@intel.com'
        try {
            #$EmailObject.SendEmail()
            $CountEmailHasSent++
        }
        catch { Write-Log -Level WARNING -Message "Faild to retrive customer data for $($server)" -Body @{ exception = $_.exception } }

        #Add time stamp to after email sent
        $sortedCsvFile[$Index++].EmailSentAt = (Get-Date -Format "MM/dd/yy HH:mm")
        #Save changes
        $sortedCsvFile | Select-Object ServerName, CustomerEmail, EmailSentAt | Export-Csv $Global:SortedServersNamePath -nti

        #Reload The file
        $sortedCsvFile = Import-Csv -Path $Global:SortedServersNamePath
    }
    #Save last changes
    $sortedCsvFile | Select-Object ServerName, CustomerEmail, EmailSentAt | Export-Csv $Global:SortedServersNamePath -nti

    $returnMessage = "Sent $($CountEmailHasSent) of $($TotalEmailToSent) emails."
    Write-Log -Level INFO -Message $returnMessage
    
    return $returnMessage
}
