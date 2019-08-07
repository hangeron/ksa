//~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//
if exists("sci.ks"){runoncepath(sci.ks).}
if exists("misc.ks"){runoncepath(misc.ks).}

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
    misc_change_rm(102).
  }

  else if runmode=102{
    if ship:verticalSpeed < 0 and alt:radar < 1000{
      misc_log("Deploy shutes!"). 
	    wait 2.
      stage.
      misc_change_rm(103).
    }
  }
  else if runmode=103{
    if verticalSpeed > -10 and alt:radar < 500{
      wait 5.
      misc_log("Collecting science").
      sci_do("science.module").
      wait 2.
      sci_do("GooExperiment").
      wait 2.
      sci_do("sensorThermometer").
      wait 2.
      sci_do("sensorBarometer").
      wait 2.
      misc_change_rm(104).
    }
  }

  else if runmode=104{
    if ship:status="Landed".{
      misc_log("Mission completed!").
      misc_change_rm(0).
    }
  }
}
wait 60.
