#Path for cvs file
$path = "C:\Users\ad_ashtaigm\Documents\log.csv"

#Un commit for create the file
#Add-Content -Path $path -Value 'Ping result, Time'

while ($true){
    #Test conecticity
    $time = (get-date).ToUniversalTime()
    $res = Test-Connection -ComputerName 'corp'-Quiet
    
    #If the ping faild
    if($res -eq $false){
        Add-Content -Path $path -Value "Disconnected, $($time)"
        Write-Host "Dis"
    }
    else{
        Write-Host "Online - $($time)"
    }
    Start-Sleep -Seconds 90
}