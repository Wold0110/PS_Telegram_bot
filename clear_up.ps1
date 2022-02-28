$files = get-childitem -path "log\" -filter "*.csv"
$logs = get-childitem -path "log\" -filter "*.log"
$c=0
$numToDel = 7
#.\log.ps1 "[clearup] started"
for($i = 0; $i+$numToDel -lt $files.Length; $i++){
    remove-item ("log\"+$files[$i])
    $c++
}
for($i = 0; $i+$numToDel -lt $logs.Length; $i++){
    remove-item ("log\"+$logs[$i])
    $c++
}

if($c -gt 0){
    .\log.ps1 ("[clearup] deleted "+$c)
}