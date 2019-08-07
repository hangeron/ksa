if exists("lib/misc.ks"){runoncepath(misc.ks).}
if exists("lib/asc.ks"){runoncepath(asc.ks).}

//-------------------- Config section ------------------------//

global targetAltitudeKm is 80.           //Orbit altitude in km.
global gravityTurnAltitude is 0.7.     //How steep should GT be.
global targetInclination is 0.           //Target inclination (heading 90 is inclination 0).
global targetAcceleration is 1.5.              //Target acceleration during ascent
global matchOrbit is "Minmus".           //To what body or ship we are going.
global randevouzTarget is "".            //Launch to catch.
global payloadTag is "Payload".          //Payload core tag
global releasePayloadStage is 3.         //Which stage releases payload.
global fairingDeploy is true.            //Should we depoly fairings?


global logEnable is true.                //Store logs on probes hard drive
global printOutEnable is false.           
//global printTarget is true.

clearscreen.
//Check if runmode is set, if not set it to 100 (prelaunch)
if exists(runmode.ks){run runmode.ks.}
else{misc_change_rm(100).}