
//~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//

set targetApoapsis to 700000.
set tergetPeriod to 4955. //1h:22m:35.7s
set divePeriod to 3304. //0h:55m:3.8s
set fairingDeploy to true.

//~~~~~~~~~~~~~~~~~~~~~ Functions ~~~~~~~~~~~~~~~~~~~~~//

function change_rm{
  parameter newMode.
  if exists(runmode.ks){deletepath(runmode.ks).}
  log "global runmode to "+newMode+"." to runmode.ks.
  set runmode to newMode.
  print "Set runmode: "+runmode.
}

function cpu_power{
  parameter cpuTag, cpuState.
  local cpu is processor(cpuTag).
  if cpuState{cpu:activate().}
  else{cpu:deactivate().}
}

function antenna_deploy{
  parameter antName, antState, antNr is 0, antTarget is "no target".
  set p to ship:partsdubbed(antName).
  set m to p[antNr]:getmodule("ModuleRTAntenna").
  if antState{
    if m:hasevent("activate"){
      m:doevent("activate"). 
      print "Antenna: "+antName+" activated.".
      if not (antTarget="no target"){
        m:setfield("target",antTarget).
        print "Antenna target: "+antTarget.
      }
    }
  }
  else{
    if m:hasevent("deactivate"){
      m:doevent("deactivate").
      print "Antenna: "+antName+" deactivated.".
    }
  }
}

function fairing_deploy{
  for m in ship:modulesnamed("ModuleProceduralFairing"){
    if m:hasevent("deploy"){
      m:doevent("deploy").
      print "Fairings deployed.".
    }
  }
}

function ascent_heading{
  parameter inclination, gravTurn. //gravTurn ecd at 0.7=49km
  return heading(inclination,arccos(min(1,max(0,apoapsis/(body:atm:height*gravTurn))))).
}

function ascent_throttle{
    //throttle to maintain constant G (throttle=Gforce*weight/maxthrust)[]=[m*s-^2]*[kg*m*s^-2]/[]
  parameter tgtAcc.
  if availablethrust > 0 {
    if alt:radar>500 and altitude<(body:atm:height*0.7){
      return min(1, tgtAcc*(body:mu/(body:radius+altitude)^2*ship:mass)/ship:availablethrust).
      }
    else{return 1.}
  }
  else {return 0.}
}

function stage_check{
  list engines in stagetrigger.
  set counteng to 0.
  set activeeng to 0.
  for eng in stagetrigger{
    if eng:flameout and eng:ignition{
      print "Dropping stage nr:"+stage:number+".".
      stage.
      break.
    }
    //Checks if engines currently on ship have been ignited, if no engines have been ignited then stage.
    //For stageing through non engine stages.
    if not eng:ignition {set activeeng to activeeng+1.}
    set counteng to counteng+1.
  }
  if counteng=activeeng{Stage.}
}
//~~~~~~~~~~~~~~~~~~~~~ Main loop ~~~~~~~~~~~~~~~~~~~~~//

clearscreen.
if exists(runmode.ks){run runmode.ks.}
else{change_rm(100).}

until runmode=0{
  if runmode=100{
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    SAS off.
    RCS off.
    lights off.
    lock throttle to 0.
    set ship:control:pilotmainthrottle to 0.
    cpu_power("CPU1", false).
    cpu_power("CPU2", false).
    cpu_power("CPU3", false).
    change_rm(runmode+1).
  }

  else if runmode=101{
    local countDown is 3.
    until countDown=0{
	    print "Launch in: "+countDown+"s.".
      set countDown to countDown-1.
	    wait 1. 
    }
    lock throttle to ascent_throttle(1.7).
    lock steering to ascent_heading(90, 1).
    print "Ignition!". 
    stage.
    change_rm(runmode+1).
  }

  else if runmode=102{
    if apoapsis > targetApoapsis*0.99{
      lock throttle to 0.1.
      change_rm(runmode+1).
    }
    stage_check().
  }

  else if runmode=103{
    if apoapsis>=targetApoapsis-5000{
      lock throttle to 0.
      brakes on.
      lights on.
      wait 5.
      kuniverse:timewarp:warpto(time:seconds + eta:apoapsis - 220).
      change_rm(runmode+1).
    }
  }

  else if runmode=104{
    if eta:apoapsis < 200{
      lock throttle to 0.1.
      change_rm(runmode+1).
    }
    else if eta:apoapsis < 215 {
      lock steering to heading(90, 0).
    }
  }

  else if runmode=105{
    if Orbit:period >= divePeriod{
      lock throttle to 0.
      cpu_power("CPU1", true).
      cpu_power("CPU2", true).
      cpu_power("CPU3", true).
      wait 1.
      stage.
      wait 1.
      stage.
      wait 1.
      stage.
      wait 60.
      antenna_deploy("Communotron 16", true, 0).
      change_rm(runmode+1).
    }
    else if orbit:period > divePeriod - 10{
      lock throttle to 0.01.
    }
  }

  else if runmode=106{

  }
  if altitude>body:atm:height*0.7 and fairingDeploy{
    fairing_deploy().
    set fairingDeploy to false.
  }
  wait 0.01.
}