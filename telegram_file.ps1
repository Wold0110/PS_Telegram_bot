#args: célszemély, fájl útvonal, szöveg
Function Send-Telegram-File {
	Param(
		[Parameter(Mandatory=$true)]
		[String]$chatId,

		[Parameter(Mandatory=$true)]
		[String]$filePath,

        [Parameter(Mandatory=$true)]
        [String]$caption
	)
	
	$Telegramtoken = get-content -path "cfg\bot.token"
    $arr = $filePath.Split('.')
    $ext = $arr[$arr.Length-1]
	Add-Type -AssemblyName System.Web
    switch ($ext) {
        "jpg"{
            (.\curl.exe -s --proxy http://165.225.200.15:80 -X POST -F photo=@$($pwd.ToString()+"\"+$filePath) "https://api.telegram.org/bot$($Telegramtoken)/sendPhoto?chat_id=$($chatId)&caption=$([System.Web.HttpUtility]::UrlEncode($caption))") > $null
            break;
        }   
        default {
            (.\curl.exe -s --proxy http://165.225.200.15:80 -X POST -F document=@$($pwd.ToString()+"\"+$filePath) "https://api.telegram.org/bot$($Telegramtoken)/sendDocument?chat_id=$($chatId)&caption=$([System.Web.HttpUtility]::UrlEncode($caption))") > $null
            break;
        }
    }
    .\log.ps1 ("[file][sent] "+$filePath+" to "+$chatId)
}
if($args.Count -gt 2){ 
	Send-Telegram-File -filePath $args[1] -chatId $args[0] -caption $args[2]
}
