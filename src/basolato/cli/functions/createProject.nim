import os, strformat, terminal
import makeFile/utils


proc createMVC(dirPath:string):int =
  try:
    createDir(dirPath)
    # download from github as dir name tmp
    let tmplateGitUrl = "https://github.com/itsumura-h/nim-basolato-templates"
    discard execShellCmd(&"""
  cd {dirPath}
  git clone {tmplateGitUrl} tmp
  """)
    # get from tmp/MVC
    moveDir(&"{dirpath}/tmp/MVC/middleware", &"{dirpath}/middleware")
    moveDir(&"{dirpath}/tmp/MVC/migrations", &"{dirpath}/migrations")
    moveFile(&"{dirpath}/tmp/MVC/main.nim", &"{dirpath}/main.nim")
    # remove tmp
    removeDir(&"{dirpath}/tmp")
    # create config.nims
    discard execShellCmd(&"""
  cd {dirPath}
  ducere make config
  """)
    # create empty dirs
    createDir(&"{dirPath}/app")
    createDir(&"{dirPath}/app/controllers")
    createDir(&"{dirPath}/app/models")
    createDir(&"{dirPath}/public")
    createDir(&"{dirPath}/public/js")
    createDir(&"{dirPath}/public/css")
    createDir(&"{dirPath}/resources")
    return 0
  except:
    echo getCurrentExceptionMsg()
    return 1

proc createDDD():int =
  return 0

proc new*(args:seq[string], architecture="MVC"):int =
  ## create new project
  var
    message:string
    packageDir:string
    dirPath:string

  if args.len > 0 and args[0].len > 0:
    packageDir = args[0]
    dirPath = getCurrentDir() & "/" & packageDir
    if isDirExists(dirPath): return 0
    message = &"create project {dirPath}"
  else:
    dirPath = getCurrentDir()
    message = &"create project {getCurrentDir()}"

  case architecture:
  of "MVC":
    message.add("\ncreate as MVC")
    styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)
    return createMVC(dirPath)
  # of "DDD":
  #   message.add("\ncreate as DDD")
  #   styledWriteLine(stdout, fgGreen, bgDefault, message, resetStyle)
  #   return createDDD()
  else:
    message = """
invalid architecture.
MVC is only available.
MVC is set by default."""
    styledWriteLine(stdout, fgRed, bgDefault, message, resetStyle)
    return 1
