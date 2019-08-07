
//~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//

set targetApoapsis to 730000.
set fairingDeploy to true.

//~~~~~~~~~~~~~~~~~~~~~ Functions ~~~~~~~~~~~~~~~~~~~~~//

function change_rm{
  parameter newMode.
  if exists(runmode.ks){deletepath(runmode.ks).}
  log "global runmode to "+newMode+"." to runmode.ks.
  set runmode to newMode.
  print "Set runmode: "+runmode.
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

function circularize_obt{
  set targetV to sqrt(ship:body:mu/(ship:orbit:body:radius+ship:orbit:apoapsis)).
  set speedAtAp to sqrt(((1-ship:orbit:ECCENTRICITY)*ship:orbit:body:mu)/((1+ship:orbit:ECCENTRICITY)*ship:orbit:SEMIMAJORAXIS)).
  set dv to targetV - speedAtAp.
  set burn_duration to dv/(ship:maxthrust/ship:mass).
  if eta:apoapsis>burn_duration/2{return node(time:seconds + eta:apoapsis, 0, 0, dv).}
  else {
    lock steering to prograde.
    lock throttle to 1.
    wait until eta:apoapsis>burn_duration/2.
    asc_circularize.
  }
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

function node_execute{
  if hasnode{
    set nd to nextnode.
    print "Executing node in: "+round(nd:eta)+"s, DeltaV: "+round(nd:deltav:mag).
    set max_acc to ship:maxthrust/ship:mass.
    set burn_duration to nd:deltav:mag/max_acc.
    print "Crude Estimated burn duration: "+round(burn_duration)+"s".
    kuniverse:timewarp:warpto(time:seconds+nd:eta-burn_duration/2-60).
    wait until nd:eta<=(burn_duration/2+60).
    set np to nd:deltav.//points to node, don't care about the roll direction.
    wait_4_steer(np).
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
        print "End burn, remain dv "+round(nd:deltav:mag,1)+"m/s, vdot: "+round(vdot(dv0,nd:deltav),1).
        lock throttle to 0.
        break.
        }
      //we have very little left to burn, less then 0.1m/s
      if nd:deltav:mag<0.1{
        print "Finalizing burn, remain dv "+round(nd:deltav:mag,1)+"m/s, vdot: "+round(vdot(dv0, nd:deltav),1).
        //we burn slowly until our node vector starts to drift significantly from initial vector
        wait until vdot(dv0,nd:deltav)<0.5.
        lock throttle to 0.
        print "End burn, remain dv "+round(nd:deltav:mag,1)+"m/s, vdot: "+round(vdot(dv0, nd:deltav),1).
        set done to True.
      }
    }
    unlock steering.
    unlock throttle.
    wait 1.
    remove nd.
    set ship:control:pilotmainthrottle to 0.
  }
  else print "No manuever node to execute.".
}

function wait_4_steer{
  parameter steerDir.
  lock steering to steerDir.
  wait until vang(steerDir,ship:facing:vector)<0.25.
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
    change_rm(runmode+1).
  }

  else if runmode=101{
    if RCS {
      RCS off.
      local countDown is 3.
      until countDown=0{
        print "Launch in: "+countDown+"s.".
        set countDown to countDown-1.
        wait 1. 
      }
      lock throttle to ascent_throttle(2).
      lock steering to ascent_heading(90, 0.7).
      print "Ignition!". 
      stage.
      change_rm(runmode+1).
    }
  }

  else if runmode=102{
    if apoapsis > targetApoapsis{
      lock throttle to 0.
      change_rm(runmode+1).
    }
    stage_check().
  }

  else if runmode=103{
    if altitude>body:atm:height{
      set warp to 0.
      wait 1.
      set circBurn to circularize_obt().
      add circBurn.
      wait 0.
      node_execute().
      change_rm(runmode+1).
    }
    else {set warp to 3.}
  }

  else if runmode=104{
    if RCS{
      RCS off.
      node_execute().
    }
  }

  if altitude>body:atm:height*0.7 and fairingDeploy{
    fairing_deploy().
    set fairingDeploy to false.
  }
  wait 0.01.
}