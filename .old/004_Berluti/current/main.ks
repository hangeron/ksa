//~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//
if exists("sci.ks"){runoncepath(sci.ks).}
if exists("misc.ks"){runoncepath(misc.ks).}
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
    misc_change_rm(102).
  }

  else if runmode=102{
    if altitude > 71000 {
      misc_log("Space reached!"). 
	    wait 1.
      misc_log("Collecting science").
      if sci_do("science.module"){sci_transmit("science.module").}
      if sci_do("GooExperiment"){sci_transmit("GooExperiment").}
      if sci_do("sensorThermometer"){sci_transmit("sensorThermometer").}
      if sci_do("sensorBarometer"){sci_transmit("sensorBarometer").}
      misc_log("Mission completed!").
      misc_change_rm(0).
    }
  }
}
wait 60.
