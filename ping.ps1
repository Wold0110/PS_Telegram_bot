#args uid target

Function portTest {
	Param(
		[Parameter(Mandatory=$true)]
		[String]$ip,

		[Parameter(Mandatory=$true)]
		[String]$port,

		[Parameter(Mandatory=$true)]
		[String]$timeout
	)

	$requestCallback = $state = $null
	$client = New-Object System.Net.Sockets.TcpClient
	$beginConnect = $client.BeginConnect($ip,$port,$requestCallback,$state)
	Start-Sleep -milli $timeout
	if ($client.Connected) { $open = $true } else { $open = $false }
	$client.Close()
	return $open 
}

try{
    $ip = $args[1].Split(':')[0]
    $port = $args[1].Split(':')[1]
    $timeout = get-content -path "cfg\timeout.cfg"
    $res = (portTest -ip $ip -port $port -timeout $timeout)
    $returnMsg = "[nok]"
    if($res){$returnMsg = "[ok]"}
    .\logMsg.ps1 ((get-date -format "yyyy-MM-dd HH:mm:ss")+"`r`n"+$ip+";"+$returnMsg) $args[0]
}
catch{
    .\telegram.ps1 $args[0] "Nem megfelelõ ip cím."
}

