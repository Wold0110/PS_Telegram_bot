#args: üzenet célszemély

if($args.count -lt 2){
    .\log.ps1 "[log][error] nincs célszemély vagy üzenet"
}

#excel check
if($args[1][0] -eq "-"){
	.\clear_up.ps1
    Add-Content -path ("log\"+(get-date -format "yyyy-MM-dd")+".csv") -value $args[0].Replace(";",",").Replace("[ok]","Rendben").Replace("[nok]","Nem elérhetõ").Replace("->,","")
	
}

.\telegram.ps1 $args[1] $args[0].Replace(";"," ")