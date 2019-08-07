
function rdv_steer {
  parameter vector.
  lock steering to vector.
  wait until vang(ship:facing:forevector, vector) < 2.
}

function rdv_approach {
  parameter craft, speed.

  lock relativeVelocity to craft:velocity:orbit - ship:velocity:orbit.
  rdv_steer(craft:position). lock steering to craft:position.

  lock maxaccel to ship:maxthrust / ship:mass.
  lock throttle to min(1, abs(speed - relativeVelocity:mag) / maxaccel).

  wait until relativeVelocity:mag > speed - 0.1.
  lock throttle to 0.
  lock steering to relativeVelocity.
}

function rdv_cancel {
  parameter craft, accuary.
  
  lock relativeVelocity to craft:velocity:orbit - ship:velocity:orbit.
  rdv_steer(relativeVelocity). lock steering to relativeVelocity.

  lock maxaccel to ship:maxthrust / ship:mass.
  lock throttle to min(1, relativeVelocity:mag / maxaccel).

  wait until relativeVelocity:mag < accuary.
  lock throttle to 0.
}


//wywalic do runmode
function rdv_await_nearest {
  parameter craft, mindistance.

  until 0 {
    set lastdistance to craft:distance.
    wait 0.5.
    if craft:distance > lastdistance or craft:distance < mindistance { break. }
  }
}