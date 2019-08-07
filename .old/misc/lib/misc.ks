
global logCounter is 0.
function misc_log{
  parameter logString.
  parameter transmitEnable is false.
  if missiontime>0{
    set logString to "(MET:+"+round(missiontime)+") "+logString.
  }
  set logCounter to logCounter+1.
  if mod(logCounter,15)=0{clearscreen.}
  print logCounter+". "+round(missiontime)+": "+logString at (0,mod(logCounter,15)).
  if transmitEnable{
    if homeconnection:isconnected{copypath("1:log.ks", "0:"+ship:name+"/"+core:tag+"/log.ks").}
    else{misc_log("Failed to upload log. No connection to Archive.").}
  }
}

function misc_change_rm{
  parameter newMode.
  if exists(runmode.ks){deletepath(runmode.ks).}
  log "global runmode to "+newMode+"." to runmode.ks.
  set runmode to newMode.
  misc_log("Set runmode: "+runmode).
}

function misc_cpu{
  parameter cpuTag, cpuState.
  local cpu is processor(cpuTag).
  if cpuState{cpu:activate().}
  else{cpu:deactivate().}
}

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
        misc_log("Antenna target: "+antTarget).
      }
    }
  }
  else{
    if m:hasevent("deactivate"){
      m:doevent("deactivate").
      misc_log("Antenna: "+antName+" deactivated.").
    }
  }
}
