while runmode=0{
  if runmode=100 {
    set ship:control:pilotmainthrottle to 0.
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    clearscreen.
    misc_log("CPU: "+core:tag+" bootup.").
    RCS off.
    SAS off.
    wait 3.
    misc_log("All systems initialized.").
    misc_change_rm(runmode+1). 
  }

  else if runmode=101{
    misc_antenna("HGcostam", 1, 0, "Kerbin").
    panels on.
    misc_change_rm(200).
  }

  else if runmode=200{
    if RCS {
      misc_log("Executing maneuver node.").
      RCS off.
      warpto(time:seconds+NEXTNODE:eta-90).
      mnv_node().
    }
    if BRAKES {
      BRAKES off.
      misc_log("Collecting science.").
      misc_change_rm(400).
    }
    if gear {
      gear off.
      misc_change_rm(0).
    }
  }

  else if runmode=400{
    set local scienceExperiments to sci_list(false). //list("dmUSGoo", "dmUSMagBoom", "dmUSMat", "USRPWS", "sensorBarometer", "kerbalism-geigercounter", "sensorThermometer").
    for exp in scienceExperiments{
      sci_do(exp).
      sci_transmit.
    }
    misc_log("Science collecting done.").
    misc_change_rm(200).
  }

  if printOutEnable{misc_print().}
  wait 0.05.
}