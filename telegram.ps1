#args: célszemély üzenet
Function Send-Telegram {
	Param(
		[Parameter(Mandatory=$true)]
		[String]$chatId,

		[Parameter(Mandatory=$true)]
		[String]$Message
	)
	
	#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	#$Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($chatId)&text=$($Message)"
	Add-Type -AssemblyName System.Web
	$msg = ([System.Web.HttpUtility]::UrlEncode($Message))
	$msg = $msg.Replace("%5bok%5d","%E2%9C%85").Replace("%5bnok%5d","%E2%9D%8C")
	(.\curl.exe -s --proxy http://165.225.200.15:80 -X POST "https://api.telegram.org/bot$(get-content -path 'cfg\bot.token')/sendMessage?chat_id=$chatId&text=$msg") > $null
}
if($args.Count -gt 1){ 
	Send-Telegram -Message $args[1] -chatId $args[0]
}
