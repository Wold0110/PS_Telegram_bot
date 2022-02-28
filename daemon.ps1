try{
Function welcomeMsg{
    Param(
        [Parameter(Mandatory=$true)]
        [String]$uid
    )
    $msg ="Üdv, ez a nagyon jól mûködõ SE MG-Zala Telegram gépezete`r`n`r`n"
    $msg+="Az alábbi parancsok vannak:`r`n"
    $msg+="/status -> lekéri az IP lista összes gépének jelenlegi állapotát`r`n"
    $msg+="/update -> lekéri egyszer az összes állapotot, majd frissítéseket küld idõközönként az állapot változásokról`r`n"
    $msg+="/ping x.x.x.x:y -> megpingel egy adott ip cím és port kombinációt`r`n"
    $msg+="/timeout  x -> átállítja a válaszra hagyott ezredmásodperceket pingnél`r`n"
    $msg+="/interval x -> hány másodpercenként teszteljen újra`r`n"
    $msg+="/newip  -> ha mellékelnek mellé fájlt akkor frissíti a cél gépek listáját`r`n"
    $msg+="/oldip  -> elküldi a jelenleg használt listát`r`n`r`n"
    $msg+="/spiderman -> elküldi mindig ugyan azt a képet`r`n"
    $msg+="/help, /start -> ez az alap információ"
    .\telegram.ps1 $uid $msg
}
$token  = get-content -path "cfg\bot.token"
$offset = get-content -path "cfg\offset.api"
Function cmdInterpeter{
    Param(
        [Parameter(Mandatory=$true)]
        [String]$cmd,
        [Parameter(Mandatory=$true)]
        [String]$uid,
        [Parameter(Mandatory=$false)]
        [String]$fileID
    )
	write-host ("|"+$cmd+"|"+$uid+"|") 
    $group = ($uid[0] -eq "-")
    $admin = test-path ("users\"+$uid+".admin")
    switch ($cmd.Split(' ')[0]){
        "status"{
            start-process powershell -windowstyle hidden ("cd '"+$pwd.ToString()+"'; .\info.ps1 "+$uid) >> $null
            break;
        }
        "myid"{
            .\telegram.ps1 $uid ("Az id: "+$uid)
            break;
        }
        "op"{
            if($admin){
                $to = $cmd.Split(' ')
                if($to.Count -gt 2){
                    $name
                    for($i = 2; $i -lt $to.Count; $i++){
                        $name+=$to[$i]+" "
                    }
                    $name=$name.Substring(0,$name.Length-1)
                    new-item -type file -path ("users\"+$to[1]+".admin") >> $null
                    Add-Content -path ("users\"+$to[1]+".admin")  -value $name
                    .\telegram.ps1 $uid "Sikeresen hozzáadva"
                }
                else{
                    .\telegram.ps1 $uid "Nincs elég paraméter a parancsban.`r`nHasználja a következõ képpen:/op *id* *név`r`n/op 12345678 Farkas Valter"
                }
            }
            else{
                .\telegram.ps1 $uid "Nincs admin jogosultsága."
            }
			break;
        }
        "bot"{
            if($group){ .\telegram.ps1 $uid "Csoportból ez nem lehetséges, csak privátban." }
            else{
                if($admin){
                    $to = $cmd.Split(' ')
                    if($to.Count -gt 1){
                        switch ($to[1]) {
                            "stop"{
                                remove-item -path "status\*"
                                new-item -type file -path "status\daemon_shutdown.command" >> $null
                                .\log ("[daemon][shutdown] by user "+$uid)
                                .\telegram $uid "Bot leállítva."
                                break;
                            }
                            "restart"{
                                .\telegram $uid "Újraindítás folyamatban..."
                                .\log ("[daemon][restart] by user "+$uid)
                                new-item -type file -path "status\daemon_shutdown.command" >> $null
								new-item -type file -path ("status\"+$uid+".restart") >> $null
                                break;
                            }
                            "download"{
                                if($to.Count -gt 2){
                                    if(test-path $to[2] ){
                                        .\log.ps1 ("[file][download] "+($to[2])+" by "+$uid)
                                        .\telegram_file.ps1 $uid $to[2] $to[2]
                                    }
                                    else{  .\telegram.ps1 $uid ("Nincs ilyen fájl, hogy: "+$to[2]+".") }
                                }
                                else{ .\telegram.ps1 $uid "Adj meg egy paramétert, fájl névre lesz szükség."}
                                break;
                            }
                            "upload"{
                                if($to.Count -gt 2){
                                    if($fileID.Length -gt 1){
                                        $fileRep = (.\curl.exe -s --proxy http://165.225.200.15:80 -X POST "https://api.telegram.org/bot$token/getFile?file_id=$fileID")
                                        $filePos = $fileRep.IndexOf("file_path")
                                        $filePath = $fileRep.Substring($filePos,($fileRep.Length-3-$filePos))
                                        $filePath = $filePath.Substring(12)

                                        (.\curl.exe -s --proxy http://165.225.200.15:80 -X POST "https://api.telegram.org/file/bot$token/$filePath" -o "download_$fileID.txt" )
                                        
                                        move-item "download_$fileID.txt" $to[2]
                                        .\log.ps1 ("[file][upload] "+$to[2]+" by "+$uid)
                                        .\telegram.ps1 $uid "Sikeres feltöltés."
                                    }
                                    else{ .\telegram.ps1 $uid "Tölts fel egy fájlt mellé." }
                                }
                                else{ .\telegram.ps1 $uid "Adj meg egy fájlnevet is ehhez a mûvelethez." }
                                break;
                            }
                            "tree"{
                                (get-childitem -recurse) > tree.txt
                                .\telegram_file.ps1 $uid "tree.txt" "Jelenlegi fájlok."
                                remove-item "tree.txt"
                                break;
                            }
                        }
                    }
                    else{ .\telegram.ps1 $uid "Adj meg egy paramétert is mellé pl:`r`nstop, restart , upload, download, tree ." }
                }
                else{
                    .\telegram.ps1 $uid "Nincs admin jogosultsága."
                }
            }
            break;
        }
        "timeout"{
            $to = $cmd.Split(' ')
            if($to.Count -gt 1){
                if($to[1] -match '^[0-9]+$'){
                    set-content -value ($to[1]) -path "cfg\timeout.cfg"
                    .\telegram $uid "Sikeresen módosítva."
                }
                else{
                    .\telegram $uid "Nem egész szám a megadott paraméter."
                }
            }
            else{
                .\telegram $uid "Nincs megadva paraméter`r`nAdj meg idõtartamot ezredmásodpercben."
            }
            break;
        }
        "interval"{
            $to = $cmd.Split(' ')
            if($to.Count -gt 1){
                if($to[1] -match '^[0-9]+$'){
                    set-content -value ($to[1]) -path "cfg\interval.cfg"
                    .\telegram $uid "Sikeresen módosítva."
                }
                else{ .\telegram $uid "Nem egész szám a megadott paraméter." }
            }
            else{ .\telegram $uid "Nincs megadva paraméter`r`nAdj meg idõtartamot másodpercben." }
            break;
        }
        "ping"{
            $to = $cmd.Split(' ')
            if($to.Count -gt 1){
                start-process powershell -windowstyle hidden ("cd '"+$pwd.ToString()+"'; .\ping.ps1 "+$uid+" "+$to[1]) >> $null
            }
            else{ .\telegram $uid "Nincs megadva paraméter.`r`nAdj meg egy IP címet és portot.`r`nPl: x.x.x.x:y -> 10.147.17.1:502" }
            break;
        }
        "update"{
            if(test-path -path ("status\update_"+$uid+".status")){
                remove-item ("status\update_"+$uid+".status")
            }
            else{
                .\telegram $uid "Update elindítva."
                (new-item -type file -path ("status\update_"+$uid+".status")) > $null
                start-process powershell -windowstyle hidden ("cd '"+$pwd.ToString()+"'; .\ping_update.ps1 "+$uid) > $null
            }
            break;
        }
        "newip"{
            if($fileID.Length -gt 1){
                $fileRep = (.\curl.exe -s --proxy http://165.225.200.15:80 -X POST "https://api.telegram.org/bot$token/getFile?file_id=$fileID")
                
                $fileRep = $fileRep.ToString()
                $filePos = $fileRep.IndexOf("file_path")
                $filePath = $fileRep.Substring($filePos,($fileRep.Length-3-$filePos))
                $filePath = $filePath.Substring(12)

                (.\curl.exe -s --proxy http://165.225.200.15:80 -X POST "https://api.telegram.org/file/bot$token/$filePath" -o "download_$fileID.txt" )

                move-item "cfg\ping_target.txt" ("cfg\ping_target_"+(get-date -format "yyyy-MM-dd_HH-mm-ss")+".txt")
                move-item "download_$fileID.txt" "cfg\ping_target.txt"
                .\log ("[target] updated by "+$uid)
                .\telegram $uid "Feltöltés sikeres."
            }
            else{ .\telegram $uid "Fájlt is kell mellékelni hozzá." }
            break;
        }
        "oldip"{
            .\telegram_file.ps1 $uid "cfg\ping_target.txt" "Jelenleg használt ping lista."
            break;
        }
        "spiderman"{
            #content
            .\telegram_file.ps1 $uid "img\spiderman.jpg" "*én amikor szerelem a telegram botot*"
			break;
        }
        "download"{
            $to = $cmd.Split(' ')
            if($to.Count -gt 1){
                if(test-path ("log\"+$to[1]) ){ .\telegram_file.ps1 $uid ("log\"+$to[1]) ("log\"+$to[1]) }
                else{ .\telegram.ps1 $uid ("Nem található a megadott fájl. ("+$to[1]+")") }
            }
            else{ .\telegram $uid "Nincs megadva paraméter.`r`nAdd meg a 'main.log' szót az alkalmazás loghoz vagy,`r`negy dátumot yyyy-mm-dd.csv formátumban. (pl: 2022-01-14.csv)" }
            break;
        }
        "help"{
            welcomeMsg -uid $uid
            break;
        }
        "start"{
            welcomeMsg -uid $uid
            break;
        }
        "?"{
            welcomeMsg -uid $uid
            break;
        }
        default{
            .\telegram.ps1 $uid "Nincs ilyen parancs, próbáld meg: /start, /help."
            break;
        }
    }
	write-host "cmd end..."
}

.\log.ps1 ("[daemon][status] start")

if($args.count -gt 0){
    .\telegram $args[0] "Újraindítás sikeres!"
}
$restart= get-childitem -path "status\" -filter "*.restart"
foreach($x in $restart){
	$uid = $x.ToString().Substring(0,$x.ToString().Length-8)
	remove-item ("status\"+$x)
	.\telegram.ps1 $uid "Sikeres újraindítás!"
}
write-host "A szolgáltatás fut."
$running=$true
while($running){
    start-sleep -Milliseconds 250
    $repC = (.\curl.exe -s --proxy http://165.225.200.15:80 -X POST "https://api.telegram.org/bot$token/getUpdates?offset=$offset&limit=1")
    if($repC.Length -ne 23){
        try{
            $rep = $repC[0]+$repC[1]
            $uiPos = $rep.IndexOf("update_id")
            $uid =  ($rep.Substring($uiPos+11,$rep.IndexOf(",",$uiPos)-($uiPos+11) ))
            $uid=([int]$uid+1)
            $offset = $uid
            set-content -path "cfg\offset.api" -value $offset
            $fromPos = $rep.IndexOf("chat")
            $fromId = ($rep.Substring($fromPos+12,$rep.IndexOf(",",$fromPos)-($fromPos+12) ))
            $textPos = $rep.IndexOf("text")
            $filePos = $rep.IndexOf("file_id")
            if($filePos -ne -1){
                .\log.ps1 "[daemon][file recived]"
                $fileID = ($rep.Substring($filePos+10,$rep.IndexOf(",",$filePos+1)-($filePos+11)))
                $cmdPos = $rep.IndexOf("caption")
                $cmd = ($rep.Substring($cmdPos+10,$rep.IndexOf(",",$cmdPos+1)-($cmdPos+11)))
                if($cmd[0] -eq "/"){ cmdInterpeter -fileID $fileID -cmd ($cmd.Substring(1)) -uid $fromId }
            }
            else{
                $text = ($rep.Substring($textPos+7,($rep.IndexOf("`"",$textPos+8)-($textPos+7))))
                if($text[0] -eq "/"){ cmdInterpeter -cmd ($text.Substring(1)) -uid $fromId}
            }
            
        }
        catch{
            .\log.ps1 ("[daemon][error]`r`n "+$repC[0]+$repC[1]+"`r`n"+$_+"`r`n"+$rep)
        }
    }
    if((test-path "status\daemon_shutdown.command")){
        remove-item "status\daemon_shutdown.command"
        $running=$false
    }
}

.\log.ps1 ("[daemon][status] stop")
}
catch{
	.\log.ps1 ("[daemon][error] critical "+$_)
}