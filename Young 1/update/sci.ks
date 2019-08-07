function sci_do{
  parameter partName, partNr is 0.
  declare p to ship:partsnamed(partName)[partNr].
  local dmms is list("ModuleScienceExperiment","DMModuleScienceAnimate","DMBathymetry").
  for module in dmms{
    if p:hasmodule(module){
      declare m to p:getmodule(module).
      if (not m:hasdata) and (not m:inoperable){
        m:deploy.
        local t to time:seconds.
        until m:hasdata or (time:seconds>t+30){wait 1.}
        misc_log("Data from "+partName+" collected.").
        return true.
      }
      else {
        misc_log("Unable to collect data from " +partName+".").
        return false.
      }
    }
  }
}


function sci_do_all{
  parameter transmit is false.
  local allModules is sci_list().
    for m in allModules{
      sci_do(m).
      if transmit{
        sci_transmit(m).
      }
    }
    misc_log("All science experiments done."). 
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
          log partCounter+". Part nammed: "+p:name+", Tittled: "+p:title+", Tagged: "+p:tag+", has Module: "+module to modules.ks.
          copypath("1:modules.ks", "0:"+ship:name+"/modules.ks").
        }
        expList:add(p:name).
      }
    }
  }
  return expList.
}

function sci_resource{
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

function sci_transmit{
  parameter partName, checkEC is false, partNr is 0.
  declare p to ship:partsnamed(partName)[partNr].
  local dmms is list("ModuleScienceExperiment","DMModuleScienceAnimate","DMBathymetry").
  for module in dmms{
    if p:hasmodule(module){
      declare m to p:getmodule(module).
      if homeconnection:isconnected and m:hasdata {
        if checkEC {
          local electric is sci_resource("ElectricCharge").
          if electric:amount<m:data[0]:dataamount*2{
            misc_log("Not enough EC to transmitt data from "+partName+".").
            return false.
          }
        }
        else {
          misc_log("Transmitting data from "+partName+".").
          m:transmit.
          return true.
        } 
      }
      else{
        misc_log("Unable to transmitt data from "+partName+".").
        return false.
      }
    }
  }
}
