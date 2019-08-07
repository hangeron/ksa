global logCounter is 0.
function misc_log{
  parameter logString.
  parameter transmitEnable is false.
  if missiontime>0{
    set logString to "(MET:+"+round(missiontime)+") "+logString.
  }
  set logCounter to logCounter+1.
  if mod(logCounter,15)=0{clearscreen.}
  if core:volume:freespace>core:volume:capacity*0.1{
    if logEnable{log logCounter+". "+round(missiontime)+": "+logString to log.ks.}
  }
  else{
    print logCounter+". "+round(missiontime)+": "+"Not enough free space on hard drive." at (0,mod(logCounter,15)).
    set logCounter to logCounter+1.
  }
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

function misc_print{
  parameter prtTgt is false.
  set line to 16.
  // print "Q:                " +ship:Q+"        " at(0,line).
  // set line to line+1.
  // print "Pressure at alt:  "+ body:atm:altitudepressure(ship:altitude)+"        " at(0,line).
  // set line to line+1.
  // print "Altitude:         " +ship:altitude+"        " at(0,line).
  // set line to line+1.
  // print "Pressure at SL:   " + (1 * constant:AtmToKPa) + " kPa.      "at(0,line).
  // set line to line+1.
  // print "RUNMODE:          "+runmode+"      " at (1,line).
  // set line to line+1.
  // print "ALTITUDE:         "+round(SHIP:ALTITUDE)+"      " at (1,line).
  // set line to line+1.
  // print "APOAPSIS:         "+round(SHIP:APOAPSIS)+"      " at (1,line).
  // set line to line+1.
  // print "PERIAPSIS:        "+round(SHIP:PERIAPSIS)+"      " at (1,line).
  // set line to line+1.
  // print "ETA to AP:        "+round(ETA:APOAPSIS)+"      " at (1,line).
  // set line to line+1.
  // print "Disc space:       "+core:volume:freespace+"/"+core:volume:capacity+"(" 
  // + round((1-core:volume:freespace/core:volume:capacity)*100)+"%)"+ "      " at (1,line).
  // set line to line+1.
   if prtTgt and hastarget{
    // print "Target distance:  "+round(target:distance)+"      " at (1,line).
    // set line to line+1.
    // print "Target angle:     "+round(mnv_target_angle())+"      " at (1,line).
    // set line to line+1.
    // print "Target speed:     "+round(target:velocity:orbit:mag)+"      " at (1,line).
    // set line to line+1.
    // print "Relative speed:   "+round((target:velocity:orbit - ship:velocity:orbit):mag)+"      " at (1,line).
    // set line to line+1.
  }
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

function misc_fairing{
  for m in ship:modulesnamed("ModuleProceduralFairing"){
    if m:hasevent("deploy"){
      m:doevent("deploy").
      misc_log("Fairings deployed.").
    }
  }
}

function misc_resource{
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
