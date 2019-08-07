function asc_steering{
  parameter inclination.
  return heading(inclination,arccos(min(1,max(0,apoapsis/(body:atm:height*0.7))))).
}

function asc_throttle{
  //throttle to maintain constant G (throttle=Gforce*weight/maxthrust)[]=[m*s-^2]*[kg*m*s^-2]/[]
  parameter tgtAcc is 1.5.
  if alt:radar>1000 and altitude<(body:atm:height*0.7){return min(1, tgtAcc*(body:mu/(body:radius+altitude))/min(0.001, ship:availablethrust)).}
  else{return 1.}
}

function asc_circularize{
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
