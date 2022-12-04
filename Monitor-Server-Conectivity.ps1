#Path for cvs file
$path = "C:\Users\ad_ashtaigm\Documents\log.csv"

#Un commit for create the file
#Add-Content -Path $path -Value 'Ping result, Time'

while ($true) {
    #Test conecticity
    $time = (get-date).ToUniversalTime()
    try {
        $res = Test-Connection -ComputerName 'corp'-Quiet    
    }
    catch {
        Add-Content -Path $path -Value "Faild to ping, $($time)"
    }
    
    $sleepTime = 90
    
    #If the ping faild
    if ($res -eq $false) {
        try {
            Add-Content -Path $path -Value "Disconnected, $($time)"
            Write-Host "Dis"
        
            #If the ping fail, reduce the ping interval to 15 second
            $sleepTime = 15
        }
        catch { Write-Warning "Faild to write log" }       
    }
    else {
        if ($sleepTime -eq 15) { $sleepTime = 90 }
        Write-Host "Online - $($time)"
    }
    Start-Sleep -Seconds $sleepTime
}