import os, strformat, terminal, strutils
import utils

proc makeController*(target:string, message:var string):int =
  let targetPath = &"{getCurrentDir()}/app/controllers/{target}_controller.nim"
  let targetCaptalized = capitalizeAscii(target)
  let CONTROLLER = &"""
from strutils import parseInt
# framework
import basolato/controller


type {targetCaptalized}Controller* = ref object of Controller

proc new{targetCaptalized}Controller(request:Request):{targetCaptalized}Controller =
  return {targetCaptalized}Controller.newController(request)


proc index*(this:{targetCaptalized}Controller):Response =
  return render("index")

proc show*(this:{targetCaptalized}Controller, idArg:string):Response =
  let id = idArg.parseInt
  return render("show")

proc create*(this:{targetCaptalized}Controller):Response =
  return render("create")

proc store*(this:{targetCaptalized}Controller):Response =
  return render("store")

proc edit*(this:{targetCaptalized}Controller, idArg:string):Response =
  let id = idArg.parseInt
  return render("edit")

proc update*(this:{targetCaptalized}Controller):Response =
  return render("update")

proc destroy*(this:{targetCaptalized}Controller, idArg:string):Response =
  let id = idArg.parseInt
  return render("destroy")
"""

  if isFileExists(targetPath): return 1

  createDir(parentDir(targetPath))

  var f = open(targetPath, fmWrite)
  f.write(CONTROLLER)
  defer: f.close()

  message = &"created controller {target}Controller"
  styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)
  return 0