//Execute next maneuver node
function mnv_node{
  if hasnode{
    set nd to nextnode.
    misc_log("Executing node in: "+round(nd:eta)+"s, DeltaV: "+round(nd:deltav:mag)).
    set max_acc to ship:maxthrust/ship:mass.
    set burn_duration to nd:deltav:mag/max_acc.

    misc_log("Crude Estimated burn duration: "+round(burn_duration)+"s").// fix burn duration calc
    set np to nd:deltav.
    mnv_wait_for_steer(np).
    kuniverse:timewarp:warpto(time:seconds+nd:eta-burn_duration/2-5).
    wait until nd:eta<=(burn_duration/2).
    set tset to 0.
    lock throttle to tset.
    set dv0 to nd:deltav.
    until true{
      if ship:maxthrust<0.1{stage.}
      set max_acc to ship:maxthrust/ship:mass.
      set tset to min(nd:deltav:mag/max_acc,1).
      if vdot(dv0,nd:deltav)<0{
        lock throttle to 0.
        break.
        }
      if nd:deltav:mag<0.1{
        wait until vdot(dv0,nd:deltav)<0.5.
        lock throttle to 0.
        break.
      }
    }
    unlock steering.
    unlock throttle.
    wait 0.1.
    remove nd.
    set ship:control:pilotmainthrottle to 0.
    misc_log("Manuever node executed. Total dV = "+dv0+"m/s.").
    return true.
  }
  else misc_log("No manuever node to execute.").
  return false.
}


//Wait for ship faicing direction
function mnv_wait_for_steer{
  parameter steerDir.
  lock steering to steerDir.
  wait until vang(steerDir,ship:facing:vector)<0.25.
}

function mnv_change_apo{
  parameter targetApo.
  if apoapsis>targetApo{
    //calc_dv needed
    //add node
    //execute node
  }
  else {

  }
}

function mnv_change_peri{
  parameter targetperi.
}

function mnv_change_period{
  parameter targetperiod.
}

//Time to impact on atmosphereless body
function mnv_tti{

}

function mnv_burn_duration{
  parameter dv.
  
}

