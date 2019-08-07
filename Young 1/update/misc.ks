global logCounter is 0.
function misc_log{
  parameter logString.
  set logString to "(MET:+"+round(missiontime)+") "+logString.
  set logCounter to logCounter+1.
  if mod(logCounter,15)=0{clearscreen.}
  if homeconnection:isconnected{log logCounter+". "+round(missiontime)+": "+logString to "1:"+ship:name+"/"+core:tag+".log".}
  print logCounter+". "+round(missiontime)+": "+logString at (0,mod(logCounter,15)).
}

//Check available resouce by type
function misc_check_resource{
  parameter searchTerm.
  local allResources to ship:resources.
  local theResult to "".
  for theResource in allResources{
    if theResource:name=searchTerm{
      set theResult to theResource.
      break.
    }
  }
  return theResult.
}


//Activate the antenna 
function misc_antenna{
  parameter antName, antState, antNr is 0, antTarget is "no target".
  set p to ship:partsdubbed(antName).
  set m to p[antNr]:getmodule("ModuleRTAntenna").
  if antState{
    if m:hasevent("activate"){
      m:doevent("activate"). 
      misc_log("Antenna: "+antName+" activated.").
      if not (antTarget="no target"){
        m:setfield("target",antTarget).
        misc_log("Selected target: "+antTarget+".").
      }
    }
  }
  else{
    if m:hasevent("deactivate"){
      m:doevent("deactivate").
      misc_log("Antenna: "+antName+" deactivated.").
      return false.
    }
  }
}


//change runmode and save it to the file
function misc_change_rm{
  parameter newMode.
  if exists(runmode.ks){deletepath(runmode.ks).}
  log "global runmode to "+newMode+"." to runmode.ks.
  set runmode to newMode.
  misc_log("Set runmode: "+runmode).
}

//Deploy all fairings
function fairing_deploy{
  for m in ship:modulesnamed("ModuleProceduralFairing"){
    if m:hasevent("deploy"){
      m:doevent("deploy").
      }
  }
  misc_log("Fairings deployed.").
}
