#args: user

if($args.count -lt 1){
	.\log.ps1 "[update] nincs célszemély"
	break;
}
.\log.ps1 ("[update] start "+$args[0])
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

if($args[0][0] -eq "-"){
	.\info.ps1 $args[0] ((get-date -format "yyyy-MM-dd")+".csv")
}
else{
	.\info.ps1 $args[0]
}

class Target{
	[ValidateNotNullOrEmpty()][String]$ip
	[ValidateNotNullOrEmpty()][String]$port
	[String]$nickname
	[Boolean]$lastVal

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

$interval = (get-content -path "cfg\interval.cfg")
$timeout = (get-content -path "cfg\timeout.cfg")

for($i = 0; $i -lt $ipArr.Count;$i++){
	$ipArr[$i].lastVal = (portTest -ip $ipArr[$i].ip -port $ipArr[$i].port -timeout $timeout)
}
Start-Sleep $interval

$running = $true
while($running){
	if( -not (test-path  ("status\update_"+$args[0]+".status")) ){
		.\logMsg.ps1 "Update;leállítva" $args[0] 
        $running=$false
    }
	else{
		$interval = (get-content -path "cfg\interval.cfg")
		$timeout = (get-content -path "cfg\timeout.cfg")
		.\logMsg.ps1 ("Frissítés indõpontja: "+(get-date -format "yyyy-MM-dd HH-mm-ss")) $args[0]
		$status=""
		$counter=0
		$available=0
		for($i = 0; $i -lt $ipArr.Count;$i++){
			$res = (portTest -ip $ipArr[$i].ip -port $ipArr[$i].port -timeout $timeout)
			if($res){++$available}
			if($res -ne $ipArr[$i].lastVal){
				$counter++
				$status+=$ipArr[$i].ip

				if($res){$status+=";[nok];->;[ok]"}
				else{$status+=";[ok];->;[nok]"}
				$status+=";"+$ipArr[$i].nickname
				$status+="`r`n"
				$ipArr[$i].lastVal = $res
			}
			if(($counter % 20 -eq 0) -and ($status -ne "")){
				$status=$status.Substring(0,$status.Length-4)
				.\logMsg.ps1 $status $args[0] 
				$status="" 
			}
		}
		if($available -eq 0){
			.\log.ps1 "[network][error] No reachable device"
			.\logMsg.ps1 "Nincs hálózat!" $args[0]
			.\alert.ps1
			start-sleep 1200
		}		
		if($counter -eq 0){ .\logMsg.ps1 "Nem történt változás." $args[0]}
		else{.\logMsg.ps1 $status $args[0]}
		
		Start-Sleep $interval
	}
}

.\log.ps1 ("[update] stopped "+$args[0])