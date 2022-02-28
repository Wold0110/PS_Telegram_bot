#args: célszemély
if($args.Count -lt 1){
	write-error "Nincs megadva célszemély."
}

.\log.ps1 ("[info] uid:"+$args[0]+" start")

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

class Target{
	[ValidateNotNullOrEmpty()][String]$ip
	[ValidateNotNullOrEmpty()][String]$port
	[String]$nickname

	Target($ip,$port, $nickname){
		$this.ip = $ip
		$this.port = $port
		$this.nickname = $nickname
	}
}

$ipListPath="cfg\ping_target.txt"
if(-Not (test-path $ipListPath)){
	write-error -Category ResourceUnavailable -Message "Nem talalhato a 'ping_target.txt' fajl" 
}

$ipList = Get-Content "cfg\ping_target.txt" -Encoding utf8

$ipArr = [System.Collections.ArrayList]@()

for($i = 0; $i -lt $ipList.Length; $i++){
	if($ipList[$i][0] -ne "#"){
		$ip = $ipList[$i].Substring(0,$ipList[$i].IndexOf(' ')).Replace(".0",".")
		$port = $ip.Split(":")[1]
		$ip = $ip.Split(":")[0]
		$nickname =  $ipList[$i].Substring($ipList[$i].IndexOf(' ')+1)
		$ipArr.Add([Target]::new($ip,$port,$nickname)) >> $null
	}
	
}

$timeout = 200

$initMsg=("A parancs most fut: "+(get-date -format "yyyy-MM-dd HH-mm-ss")+"`r`n")
$initMsg+="Ez alatt található lesz minden gép jelenlegi adata."
.\logMsg.ps1 $initMsg $args[0]  

$status=""
for($i = 0; $i -lt $ipArr.Count;$i++){
	$res = (portTest -ip $ipArr[$i].ip -port $ipArr[$i].port -timeout $timeout)
	$status+=""+$ipArr[$i].ip+";"
	
	if($res){ $status+="[ok]" }
	else{ $status+="[nok]" }
	$status+=";"+$ipArr[$i].nickname+"`r`n"

	if($i % 20 -eq 0){
		.\logMsg.ps1 $status $args[0]
		$status=""
	}
}

.\logMsg.ps1 $status $args[0]
.\log.ps1 ("[info] uid:"+$args[0]+" done")
#breakline '`r`n'
