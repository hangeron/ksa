

//~~~~~~~~~~~~~~~~~~~~~ Functions ~~~~~~~~~~~~~~~~~~~~~//

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

function sci_do{
  parameter partName, partNr is 0.
  declare p to ship:partsnamed(partName)[partNr].
  local dmms is list("ModuleScienceExperiment","DMModuleScienceAnimate","DMBathymetry").
  for module in dmms{
    if p:hasmodule(module){
      declare m to p:getmodule(module).
      if (not m:hasdata) and (not m:inoperable){
        misc_log("Collecting data from "+partName+".").
        m:deploy.
        local t to time:seconds.
        until m:hasdata or (time:seconds>t+30){wait 1.}
        misc_log("Data collected.").
        return true.
      }
    }
  }
}

function sci_transmit{
  parameter partName, partNr is 0.
  declare p to ship:partsnamed(partName)[partNr].
  local dmms is list("ModuleScienceExperiment","DMModuleScienceAnimate","DMBathymetry").
  for module in dmms{
    if p:hasmodule(module){
      declare m to p:getmodule(module).
      local electric is sci_resource("ElectricCharge").
      if homeconnection:isconnected and m:hasdata and (electric:amount>m:data[0]:dataamount*2){
        misc_log("Transmitting data from "+partName+".").
        m:transmit.
         return true.
      }
      return false.
    }
  }
}

function fairing_deploy{
  for m in ship:modulesnamed("ModuleProceduralFairing"){
    if m:hasevent("deploy"){
      m:doevent("deploy").
      misc_log("Fairings deployed.").
    }
  }
}

//~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//
clearscreen.
if exists(runmode.ks){run runmode.ks.}
else{misc_change_rm(100).}


//~~~~~~~~~~~~~~~~~~~~~ Main loop ~~~~~~~~~~~~~~~~~~~~~//
until runmode=0{
  if runmode=100{
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    SAS off.
    RCS off.
    lights off.
    lock throttle to 0.
    set ship:control:pilotmainthrottle to 0.
    misc_change_rm(101).
  }

  else if runmode=101{
    local countDown is 3.
    until countDown=0{
	    misc_log("Launch in: "+countDown+"s.").
      set countDown to countDown-1.
	    wait 1. 
    }
    misc_log("Ignition!"). 
    stage.
    wait 1.
    stage.
    misc_change_rm(102).
  }

  else if runmode=102{
    if altitude > 70000 {
      misc_log("Space reached!"). 
      fairing_deploy().
      wait 1.
      stage.
      misc_change_rm(103).
    }
  }
  else if runmode=103{
    if eta:apoapsis < 30 {
      lock steering to prograde. 
      wait 10.
      lock throttle to 1.
      misc_change_rm(104).
    }
  }
  else if runmode=104{
    if periapsis > 71000 {
      misc_log("Orbit reached!").
      lock throttle to 0.
      misc_change_rm(200).
    }
  }
  else if runmode=200{
    sci_do("sensorThermometer").
    sci_do("sensorBarometer").
    misc_change_rm(201).
  }
  else if runmode=201{
    if eta:periapsis < 30 {
      lock steering to retrograde.
      misc_change_rm(202).
    }
  }
  else if runmode=202{
    if eta:periapsis < 10 {
      lock throttle to 1.
      misc_change_rm(203).
    }
  }
  else if runmode=203{
    if periapsis < 40000 {
      lock throttle to 0.
      wait 1.
      stage.
      misc_change_rm(204).
    }
  }
  else if runmode=204{
    if alt:radar < 2000 {
      stage.
      misc_log("Mission completed.").
      misc_change_rm(0).
    }
  }
}
wait 60.