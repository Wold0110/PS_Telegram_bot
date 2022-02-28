$users = Get-ChildItem -path "users\"
foreach($x in $users){
    $arr = $x.ToString().Replace(".admin","").Split("\")
    $user = $arr[$arr.Count-1]
    Write-Host $user
    .\telegram.ps1 $user "Nincs hálózati elérés az egész cél tartományon!"
}