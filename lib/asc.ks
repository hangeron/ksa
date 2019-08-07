//Calculates curcularize burn and returns node 
function asc_circularize{
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

//Steering during ascent phase
function asc_heading{
  parameter inclination, gravTurn. //gravTurn ecd at 0.7=49km
  return heading(inclination,arccos(min(1,max(0,apoapsis/(body:atm:height*gravTurn))))).
}

//Throttle during ascent phase 
function asc_throttle{
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

//Checks if engines currently on ship have been ignited, if no engines have been ignited then stage.
//For stageing through non engine stages.
function asc_stage{
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