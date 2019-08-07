

//-------------------- Config processing ---------------------//

set targetAltitude to targetAltitudeKm*1000.
if MatchOrbit="" {
  if randevouzTarget <> "" {
    set target to randevouzTarget.
    set waitingFor to "approach".
  }
  else {set waitingFor to "".}
}
else {
  set target to matchOrbit.
  set targetInclination to target:orbit:inclination. 
  //target:orbit:lan + body:rotationangle . //longitude of ascending node
  set waitingFor to "ascending node".
}



//-------------------- Functions definitions -----------------//



//-------------------- Main program execution ----------------//

while runmode=0{
  //Pre config (brakes, lights, gears, throttle, put all payload cores to sleep)
  if runmode=100 {
    set ship:control:pilotmainthrottle to 0.
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    clearscreen.
    misc_log("CPU: "+core:tag+" bootup.").
    RCS off.
    SAS off.
    misc_cpu(payloadTag, false).
    wait 1.
    misc_log("All systems initialized.").
    misc_change_rm(runmode+1). 
  }
  
  //Warp to launch (catch target at orbit or ascending node )
  else if runmode=101 {
    if waitingFor=""{
      misc_log("Ready for launch.").
      misc_change_rm(200). 
    }
    else if waitingFor="approach"{
      misc_log("Waiting for target aproach.").
      misc_change_rm(102).
    }
    else if waitingFor="ascending node"{
      misc_log("Waiting for ascending node launch window (AG1).").
      misc_change_rm(103).
    }
  }

  //Wait for target approach
  else if runmode=102{
    if mnv_target_angle()>targetAngleAtLaunch and mnv_target_angle()<targetAngleAtLaunch+1 {
      set kuniverse:timewarp:rate to 1.
      wait 1.
      misc_log("Target in sight, ready to launch.").
      misc_change_rm(200).
    }
    else if mnv_target_angle()>(targetAngleAtLaunch-3){set kuniverse:timewarp:rate to 5.}
    else if mnv_target_angle()>(targetAngleAtLaunch-10){set kuniverse:timewarp:rate to 10.}
    else if mnv_target_angle()>(targetAngleAtLaunch-30){set kuniverse:timewarp:rate to 50.}
    else {set kuniverse:timewarp:rate to 100.}
  }

  //Wait for ascending node
  else if runmode=103{
    if AG1{
      AG1 off.
      misc_log("Ready to launch.").
      misc_change_rm(200).
    }
  }

  //Set throttle & heading & pitch functions (target pitch 45 at 10km)
  else if runmode=200{
    lock throttle to asc_throttle(targetAcceleration).
    lock steering to asc_steering(targetInclination).
    local countDown is 3.
    until countDown=0{
      misc_log(countDown).
      countDown=countDown-1.
    }
    stage.
    misc_log("Ignition!!").
    misc_change_rm(runmode+1).
  }
  
  else if runmode=201{
    if apoapsis >= targetAltitude{
      lock throttle to 0.
      lock steering to prograde.
      misc_log("Ascent burn finished.").
      misc_change_rm(runmode+1).
    }
    mnv_stage().
  }

  else if runmode=202{
    if altitude>body:atm:height{
      set warp to 0.
      wait 1.
      set circBurn to asc_circularize().
      add circBurn.
      wait 0.
      mnv_node().
      misc_change_rm(runmode+1).
    }
    else {set warp to 3.}
  }
  
  else if runmode=203{
    misc_log("Orbit reached, activating Payload cores.").
    misc_cpu(payloadTag, True).
    wait 1.
    misc_log("Waiting for command to release payload (AG1)"). 
    misc_change_rm(runmode+1).
  }

  else if runmode=204{
    if AG1{
      AG1 off.
      until stage:number = releasePayloadStage{stage.wait 1.}
      misc_log("Payload released").
      wait 1.
      misc_change_rm(300).
    }
  }

  else if runmode=300{
    wait 5.
    panels on.
    lock steering to retrograde.
    misc_log("Waiting for deorbit burn instructions (AG1)").
    misc_change_rm(runmode+1).
  }

  else if runmode=301{
    if AG1{
      AG1 off.
      misc_log("Beginning deorbit procedure.").
      misc_change_rm(runmode+1).
    }
  }

  else if runmode=302{
    lock throttle to 0.3.
    if periapsis<0.6*body:atm:height{
      lock throttle to 0.
      panels off.
      wait 0.
      unlock throttle.
      misc_change_rm(runmode+1).
    }

  else if runmode=303{
    if alt:radar<3000{
      lock steering to mnv_upward().
      misc_change_rm(runmode+1).
    }
  }

  if runmode=304{
    if mnv_tti(0) <= mnv_time(abs(ship:airspeed)){
      lock throttle to 1.
      misc_change_rm(runmode+1).
    }
  }

  if runmode=305{
    if ship:verticalspeed>-50{
      set hoverPid to pidloop(0.04, 0.003, 0.005, 0, 1).
      set pidThrottle to 0.
      lock throttle to pidThrottle.
      misc_change_rm(runmode+1).
    }
  }

  if runmode=103{
    if alt:radar > 200{
      set hoverPid:setpoint to -100.
    }
    else if alt:radar > 40{
      set hoverPid:setpoint to -40.
    }
    else if alt:radar > 10{
      set hoverPid:setpoint to -10.
    }    
    else {
      set hoverPid:setpoint to -4.
    }
    set pidThrottle to hoverPid:update(time:seconds, ship:verticalspeed).
    if ship:status = "LANDED" {
      lock throttle to 0.
      wait 10.
      misc_log("Mission completed.", true).
      unlock steering.
      misc_change_rm(0).
    }
  }

  if (fairingDeploy)and(altitude>body:atm:height*0.8){
    set fairingDeploy to false.
    misc_fairing().
  }
  if printOutEnable{misc_print().}
  wait 0.05.
}