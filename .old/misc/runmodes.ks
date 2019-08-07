//---------------------- old lift
  if runmode=100{
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    SAS off.
    RCS off.
    lights off.
    lock throttle to 0.
    set ship:control:pilotmainthrottle to 0.
    if targetName = ""{
      misc_change_rm(102).
    }
    else{
      set target to targetName.
      misc_change_rm(101).
    }
    wait 1.
  }
  else if runmode=101{
    if mnv_target_angle()>targetAngleAtLaunch and mnv_target_angle()<targetAngleAtLaunch+1 {
      set kuniverse:timewarp:rate to 1.
      wait 3.
      misc_change_rm(runmode+1).
    }
    else if mnv_target_angle()>(targetAngleAtLaunch-3){set kuniverse:timewarp:rate to 5.}
    else if mnv_target_angle()>(targetAngleAtLaunch-10){set kuniverse:timewarp:rate to 10.}
    else if mnv_target_angle()>(targetAngleAtLaunch-30){set kuniverse:timewarp:rate to 50.}
    else {set kuniverse:timewarp:rate to 100.}
  }

  else if runmode=102{
    lock steering to asc_steering(headingAtLaunch, gravTurnStop, targetAltitude).
    lock throttle to asc_throttle(ascThrottleBase, ascThrottleMultiply, ascThrottleAltitude).
    stage.
    misc_change_rm(runmode+1).
  }
  else if runmode=103{
    if stage:number > ascentStage {
      mnv_stage().
    }
    else if maxthrust<1{
      lock throttle to 0.
      lock steering to heading(headingAtLaunch, 0).
      misc_change_rm(runmode+1).
      break.
    }
    if apoapsis >= targetAltitude{
      lock throttle to 0.
      lock steering to heading(headingAtLaunch, 0).
      misc_change_rm(runmode+1).
    }
  }
  else if runmode=104{
    if altitude >= body:atm:height*0.9 {
      misc_fairing().
      wait 1.
      //misc_antenna("HG-5 High Gain Antenna", true, 0, "Kerbin").
      //misc_antenna("Communotron 16", true, 0, "no target").
      panels on.
      stage.
      misc_change_rm(runmode+1).
    }
  }
  else if runmode=105{
    lock throttle to 1.
    lock steering to heading(headingAtLaunch, 0).
    if apoapsis>=targetAltitude{ 
      lock throttle to 0.
      misc_change_rm(runmode+1).
    }
  }
  else if runmode=106{
    set circNode to asc_circularize().
    add circNode.
    wait 1.
    set burnDuration to circNode:deltav:mag/(ship:maxthrust/ship:mass).
    if circNode:eta>burnDuration/2+30 {warpto(time:seconds+circNode:eta-(burnDuration/2+20)).}
    mnv_node().
    misc_change_rm(200).
  }

//-----------------------------------mnv node
  else if runmode=200{
    if RCS {
      RCS off.
      warpto(time:seconds+NEXTNODE:eta-90).
      mnv_node().
    }
    if BRAKES {
      BRAKES off.
      misc_change_rm(400).
    }
    if gear {
      gear off.
      misc_change_rm(0).
    }
  }

//------------------------ randezvous
  else if runmode=400{
    if target:distance>2000{
     rdv_cancel(target, 1).
      rdv_approach(target, 50).
      rdv_await_nearest(target, 2000).
    }
    else if target:distance > 1000{
      rdv_cancel(target, 1).
      rdv_approach(target, 10).
      rdv_await_nearest(target, 100).
    }
    else if target:distance > 100 {
      rdv_cancel(target, 1).
      rdv_approach(target, 10).
      rdv_await_nearest(target, 100).
    }
    else {
      rdv_cancel(target, 0.1).
      misc_change_rm(200).
    }
  }

//----------------------------------Science

 else if runmode=400{
    sci_do("dmUSGoo").
    sci_do("dmUSMagBoom").
    sci_do("dmUSMat").
    sci_do("USRPWS").
    sci_do("sensorBarometer").
    sci_do("kerbalism-geigercounter").
    sci_do("sensorThermometer").
    wait 5.
    sci_transmit("dmUSGoo").
    sci_transmit("dmUSMagBoom").
    sci_transmit("dmUSMat").
    sci_transmit("USRPWS").
    sci_transmit("sensorBarometer").
    sci_transmit("kerbalism-geigercounter").
    sci_transmit("sensorThermometer").
    misc_change_rm(200).
  }
