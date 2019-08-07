function check_update{
	if homeconnection:isconnected{
		switch to 0.
		if exists(ship:name+"/"+core:tag+"/update"){
			cd(ship:name+"/"+core:tag+"/update/").
			list files in filesToUpdate.
			for file in filesToUpdate{
				if exists("1:"+file){copypath("1:"+file,"0:"+ship:name+"/"+core:tag+"/previous/"+file).}
				copypath("0:"+ship:name+"/"+core:tag+"/update/"+file,"1:").
				copypath("0:"+ship:name+"/"+core:tag+"/update/"+file,"0:"+ship:name+"/"+core:tag+"/current/"+file).
				deletepath("0:"+ship:name+"/"+core:tag+"/update/"+file).
				print "Ship: "+ship:name+", CPU: "+core:tag+", "+file+" updated.".
				wait 1.
			}
		}
		switch to 1.
		wait 0.
	}
}
check_update().
if exists("maintenance.ks"){run maintenance.ks.	deletepath(maintenance.ks).}
if exists("main.ks"){run main.ks.}
local countDown is 4.
until countDown=0{
	clearScreen.
	print "Reboot in: "+countDown+"s.".
    set countDown to countDown-1.
	wait 1.
}
reboot.