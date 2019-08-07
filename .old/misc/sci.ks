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
        until m:hasdata or (time:seconds>t+10){wait 1.}
        misc_log("Data collected.").
        return true.
      }
    }
  }
}

function sci_transmit{
  parameter partName, partNr is 0.
  declare p to ship:partsnamed(partName)[partNr].
  local dmms is list("ModuleScienceExperiment","DMModuleScienceAnimate","DMBathymetry").
  for module in dmms{
    if p:hasmodule(module){
      declare m to p:getmodule(module).
      local electric is misc_resource("ElectricCharge").
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