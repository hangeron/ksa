function mnv_lng_2_deg{
  parameter lng.
  return mod(lng+360,360).
}
  
function mnv_target_angle{
  return mod(mnv_lng_2_deg(target:longitude)-mnv_lng_2_deg(ship:longitude)+360,360).
}

function mnv_stage{
  list engines in stagetrigger.
  set counteng to 0.
  set activeeng to 0.
  for eng in stagetrigger{
    if eng:flameout and eng:ignition{
      misc_log("Dropping stage nr:"+stage:number+".").
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

function mnv_node{
  if hasnode{
    set nd to nextnode.
    misc_log("Executing node in: "+round(nd:eta)+"s, DeltaV: "+round(nd:deltav:mag)).
    set max_acc to ship:maxthrust/ship:mass.
    set burn_duration to nd:deltav:mag/max_acc.
    misc_log("Crude Estimated burn duration: "+round(burn_duration)+"s").
    kuniverse:timewarp:warpto(time:seconds+nd:eta-burn_duration/2-60).
    wait until nd:eta<=(burn_duration/2+60).
    set np to nd:deltav.//points to node, don't care about the roll direction.
    mnv_wait_4_steer(np).
    wait until nd:eta<=(burn_duration/2).
    set tset to 0.
    lock throttle to tset.
    set done to False.
    //initial deltav
    set dv0 to nd:deltav.
    until done{
      //recalculate current max_acceleration
      set max_acc to ship:maxthrust/ship:mass.
      if ship:maxthrust<0.1{stage.}
      //when there is less than 1 second - decrease the throttle linearly
      set tset to min(nd:deltav:mag/max_acc,1).
      //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
      //this check is done via checking the dot product of those 2 vectors
      if vdot(dv0,nd:deltav)<0{
        misc_log("End burn, remain dv "+round(nd:deltav:mag,1)+"m/s, vdot: "+round(vdot(dv0,nd:deltav),1)).
        lock throttle to 0.
        break.
        }
      //we have very little left to burn, less then 0.1m/s
      if nd:deltav:mag<0.1{
        misc_log("Finalizing burn, remain dv "+round(nd:deltav:mag,1)+"m/s, vdot: "+round(vdot(dv0, nd:deltav),1)).
        //we burn slowly until our node vector starts to drift significantly from initial vector
        wait until vdot(dv0,nd:deltav)<0.5.
        lock throttle to 0.
        misc_log("End burn, remain dv "+round(nd:deltav:mag,1)+"m/s, vdot: "+round(vdot(dv0, nd:deltav),1)).
        set done to True.
      }
    }
    unlock steering.
    unlock throttle.
    wait 1.
    remove nd.
    set ship:control:pilotmainthrottle to 0.
  }
  else misc_log("No manuever node to execute.").
}

function mnv_wait_4_steer{
  parameter steerDir.
  lock steering to steerDir.
  wait until vang(steerDir,ship:facing:vector)<0.25.
}

// Time to impact
function mnv_tti {
  parameter margin.
  local d is alt:radar - margin.
  local v is -ship:verticalspeed.
  local g is ship:body:mu / ship:body:radius^2.
  return (sqrt(v^2 + 2 * g * d) - v) / g.
}

// Time to complete a maneuver
function mnv_time {
  parameter dv.
  set ens to list().
  ens:clear.
  set ens_thrust to 0.
  set ens_isp to 0.
  list engines in myengines.

  for en in myengines {
    if en:ignition = true and en:flameout = false {
      ens:add(en).
    }
  }

  for en in ens {
    set ens_thrust to ens_thrust + en:availablethrust.
    set ens_isp to ens_isp + en:isp.
  }

  if ens_thrust = 0 or ens_isp = 0 {
    misc_log("No engines available!").
    return 0.
  }
  else {
    local f is ens_thrust * 1000.  // engine thrust (kg * m/s²)
    local m is ship:mass * 1000.        // starting mass (kg)
    local e is constant():e.            // base of natural log
    local p is ens_isp/ens:length.               // engine isp (s) support to average different isp values
    local g is ship:orbit:body:mu/ship:obt:body:radius^2.    // gravitational acceleration constant (m/s²)
    return g * m * p * (1 - e^(-dv/(g*p))) / f.
  }
}

function mnv_upward{
  if ship:verticalspeed < -2 {
    return srfretrograde.
  } else {
    return ship:up.
  }
}