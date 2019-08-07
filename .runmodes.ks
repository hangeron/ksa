/~~~~~~~~~~~~~~~~~~~~~ Configuration ~~~~~~~~~~~~~~~~~~~~~//

set targetApoapsis to 80000.
set fairingDeploy to true.

//~~~~~~~~~~~~~~~~~~~~~ Functions ~~~~~~~~~~~~~~~~~~~~~//

//change runmode and save it to the file
function change_rm{
  parameter newMode.
  if exists(runmode.ks){deletepath(runmode.ks).}
  log "global runmode to "+newMode+"." to runmode.ks.
  set runmode to newMode.
  print "Set runmode: "+runmode.
}

//Deploy all fairings
function fairing_deploy{
  for m in ship:modulesnamed("ModuleProceduralFairing"){
    if m:hasevent("deploy"){
      m:doevent("deploy").
      print "Fairings deployed.".
    }
  }
}

//Steering during ascent phase
function ascent_heading{
  parameter inclination, gravTurn. //gravTurn ecd at 0.7=49km
  return heading(inclination,arccos(min(1,max(0,apoapsis/(body:atm:height*gravTurn))))).
}

//Throttle during ascent phase
function ascent_throttle{
    //throttle to maintain constant G (throttle=Gforce*weight/maxthrust)[]=[m*s-^2]*[kg*m*s^-2]/[]
  parameter tgtAcc.
  if availablethrust > 0 {
    if alt:radar>500 and altitude<(body:atm:height*0.5){
      return min(1, tgtAcc*(body:mu/(body:radius+altitude)^2*ship:mass)/ship:availablethrust).
      }
    else{return 1.}
  }
  else {return 0.}
}

//Calculates curcularize burn and returns node 
function circularize_obt{
  set targetV to sqrt(ship:body:mu/(ship:orbit:body:radius+ship:orbit:apoapsis)).
  set speedAtAp to sqrt(((1-ship:orbit:ECCENTRICITY)*ship:orbit:body:mu)/((1+ship:orbit:ECCENTRICITY)*ship:orbit:SEMIMAJORAXIS)).
  set dv to targetV - speedAtAp.
  set burn_duration to dv/(ship:maxthrust/ship:mass).
  if eta:apoapsis>burn_duration/2{
    return node(time:seconds + eta:apoapsis, 0, 0, dv).
  }
  else {
    lock steering to prograde.
    lock throttle to 1.
    wait until eta:apoapsis>burn_duration/2.
    asc_circularize.
  }
}

//Checks if engines currently on ship have been ignited, if no engines have been ignited then stage.
//For stageing through non engine stages.
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
    if not eng:ignition {set activeeng to activeeng+1.}
    set counteng to counteng+1.
  }
  if counteng=activeeng{Stage.}
}

//execute next node
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
    //wait for steer
    lock steering to np.
    wait until vang(np,ship:facing:vector)<0.25.
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

//Wait for shipp faicing direction
function wait_4_steer{
  parameter steerDir.
  lock steering to steerDir.
  wait until vang(steerDir,ship:facing:vector)<0.25.
}


function misc_antenna{
  parameter antName, antState, antNr is 0, antTarget is "no target".
  set p to ship:partsdubbed(antName).
  set m to p[antNr]:getmodule("ModuleRTAntenna").
  if antState{
    if m:hasevent("activate"){
      m:doevent("activate"). 
      misc_log("Antenna: "+antName+" activated.").
      if not (antTarget="no target"){
        m:setfield("target",antTarget).
        misc_log("Antenna target: "+antTarget).
      }
    }
  }
  else{
    if m:hasevent("deactivate"){
      m:doevent("deactivate").
      misc_log("Antenna: "+antName+" deactivated.").
    }
  }
}

function sci_do{
  parameter partName, partNr is 0.
  declare p to ship:partsnamed(partName)[partNr].
  local dmms is list("ModuleScienceExperiment","DMModuleScienceAnimate","DMBathymetry").
  for module in dmms{
    if p:hasmodule(module){
      declare m to p:getmodule(module).
      if (not m:hasdata) and (not m:inoperable){
        misc_log("Collecting data from "+partName+".").
        m:deploy.
        local t to time:seconds.
        until m:hasdata or (time:seconds>t+30){wait 1.}
        misc_log("Data collected.").
        return true.
      }
    }
  }
}

//Transmit data if 
function sci_transmit{
  parameter partName, partNr is 0.
  declare p to ship:partsnamed(partName)[partNr].
  local dmms is list("ModuleScienceExperiment","DMModuleScienceAnimate","DMBathymetry").
  for module in dmms{
    if p:hasmodule(module){
      declare m to p:getmodule(module).
      for theResource in ship:resources{
        if theResource:name="ElectricCharge"{
        set theResult to theResource.
        break.
        }
      }
      if homeconnection:isconnected and m:hasdata and (electric:amount>m:data[0]:dataamount*2){
        misc_log("Transmitting data from "+partName+".").
        m:transmit.
         return true.
      }
      return false.
    }
  }
}

function sci_list{
  parameter logResult is false.
  list parts in allPartList.
  set partCounter to 0.
  local dmms is list("ModuleScienceExperiment", "DMModuleScienceAnimate", "DMBathymetry").
  local expList is list().
  for p in allPartList{
    for module in dmms{
      if p:hasmodule(module){
        if logResult{
          set partCounter to partCounter+1.
          print partCounter+". Part nammed: "+p:name+", Tittled: "+p:title+", Tagged: "+p:tag+", has Module: "+module.
          log partCounter+". Part nammed: "+p:name+", Tittled: "+p:title+", Tagged: "+p:tag+", has Module: "+module to modules.ks.
          copypath("1:modules.ks", "0:"+ship:name+"/modules.ks").
        }
        expList:add(p:name).
      }
    }
  }
  return expList.
}


function check_resource{
  parameter searchTerm.
  local allResources to ship:resources.
  local theResult to "".
  for theResource in allResources{
    if theResource:name=searchTerm{
      set theResult to theResource.
      break.
    }
  }
  return theResult.
}
