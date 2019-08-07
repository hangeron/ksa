clearscreen.

run config.ks.
print "Maitenance script execution.".
function print_science {
  list parts in allPartList. 
  set partCounter to 0.
  local DMMS to list("ModuleScienceExperiment", "DMModuleScienceAnimate", "DMBathymetry").
  for P in allPartList {
    for module in DMMS {
    if P:HASMODULE(module) {
      set partCounter to partCounter + 1.
      print partCounter + ". Part nammed: " + P:name + ", Tittled: " + p:title + ", Tagged: " + p:tag + ", has Module: " + module.
      log partCounter + ". Part nammed: " + P:name + ", Tittled: " + p:title + ", Tagged: " + p:tag + ", has Module: " + module to modules.ks.
      copypath("1:modules.ks", "0:"+ship:name + "/modules.ks").
      } 
    }
  } 
} 
print_science.
sci_do("dmGoreSat").
wait 5.
sci_transmit("dmGoreSat").
wait 100.