
//~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//
runOncePath("misc.ks").
runOncePath("sci.ks").
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
    misc_change_rm(runmode+1).
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
    wait 3.
    misc_change_rm(runmode+1).
  }

  else if runmode=102{
    if verticalSpeed<5{
      sci_do_all(true).
      stage.
      misc_change_rm(runmode+1).
    }
  }

  else if runmode=103{
    if not (ship:status = "flying") {
      misc_log("Mission completed.").
      misc_change_rm(0).
    }
  }
}
wait 30.