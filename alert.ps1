$users = Get-ChildItem -path "users\"
foreach($x in $users){
    $arr = $x.ToString().Replace(".admin","").Split("\")
    $user = $arr[$arr.Count-1]
    Write-Host $user
    .\telegram.ps1 $user "Nincs h�l�zati el�r�s az eg�sz c�l tartom�nyon!"
}