
//~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//

set targetApoapsis to 700000.
set targetPeriod to 4955. //1h:22m:35.7s
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

//~~~~~~~~~~~~~~~~~~~~~ Main loop ~~~~~~~~~~~~~~~~~~~~~//

clearscreen.
if exists(runmode.ks){run runmode.ks.}
else{change_rm(100).}

until runmode=0{
  if runmode=100{
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    SAS off.
    RCS off.
    lights on.
    lock throttle to 0.
    set ship:control:pilotmainthrottle to 0.
    wait 5.
    change_rm(runmode+1).
  }

  else if runmode=101{
    if missiontime > divePeriod*2 {
      lock steering to prograde.
      change_rm(runmode+1).//0,1,2
    }
  }

  else if runmode=102{
    set targetV to sqrt(ship:body:mu/(ship:orbit:body:radius+ship:orbit:apoapsis)).
    set speedAtAp to sqrt(((1-ship:orbit:ECCENTRICITY)*ship:orbit:body:mu)/((1+ship:orbit:ECCENTRICITY)*ship:orbit:SEMIMAJORAXIS)).
    set dv to targetV - speedAtAp.
    set burnDuration to dv/(ship:maxthrust/ship:mass).
    if eta:apoapsis<=burnDuration/2{
      lock throttle to 1.
      change_rm(runmode+1).
    }
  }

  else if runmode=103{
    if orbit:period>=targetPeriod{
      lock throttle to 0.
      panels on.
      antenna_deploy("HG-5 High Gain Antenna", true, 0, "Mun").
      antenna_deploy("Communotron 16", true, 0).
      change_rm(runmode+1).
    }
    else if orbit:period > targetPeriod-10{
      lock throttle to 0.001.
    }
    else if orbit:period > targetPeriod-100{
      lock throttle to 0.1.
    }
  }

  else if runmode=104{
    change_rm(0).
    deletepath(runmode.ks).
    deletepath(main.ks).
  }
  wait 0.01.
}