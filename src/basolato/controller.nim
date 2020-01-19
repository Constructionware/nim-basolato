import json, os, httpcore, httpcore, random, std/sha1, times, strutils, options, tables
import jester except setCookie
import jester/private/utils
import flatdb
import base


export httpcore, base
export jester except redirect, setCookie

type Controller* = ref object of RootObj


# String
proc render*(body:string):Response =
  return Response(status:Http200, bodyString:body, responseType:String)

proc render*(status:HttpCode, body:string):Response =
  return Response(status:status, bodyString:body, responseType:String)


# Json
proc render*(body:JsonNode):Response =
  return Response(status:Http200, bodyJson:body, responseType:Json)

proc render*(status:HttpCode, body:JsonNode):Response =
  return Response(status:status, bodyJson:body, responseType:Json)


proc redirect*(url:string) : Response =
  return Response(
    status:Http303, url:url, responseType: Redirect
  )

proc errorRedirect*(url:string): Response =
  return Response(
    status:Http302, url:url, responseType: Redirect
  )
  

# with header
proc header*(r:Response, key:string, value:string):Response =
  var response = r
  response.headers.add(
    (key, value)
  )
  return response

proc header*(r:Response, key:string, valuesArg:openArray[string]):Response =
  var response = r
  
  var value = ""
  for i, v in valuesArg:
    if i > 0:
      value.add(", ")
    value.add(v)

  response.headers.add((key, value))
  return response

proc setCookie*(r:Response, c:string): Response =
  r.header("Set-cookie", c)

# load html
proc html*(r_path:string):string =
  ## arg r_path is relative path from /resources/
  block:
    let path = getCurrentDir() & "/resources/" & r_path
    let f = open(path, fmRead)
    result = $(f.readAll)
    defer: f.close()

# =============================================================================

proc rundStr():string =
  randomize()
  for _ in .. 50:
    add(result, char(rand(int('A')..int('z'))))

proc genCookie*(name, value: string, expires="",
                    sameSite: SameSite=Lax, secure = false,
                    httpOnly = false, domain = "", path = ""): string =
  ## Creates a cookie which stores ``value`` under ``name``.
  ##
  ## The SameSite argument determines the level of CSRF protection that
  ## you wish to adopt for this cookie. It's set to Lax by default which
  ## should protect you from most vulnerabilities. Note that this is only
  ## supported by some browsers:
  ## https://caniuse.com/#feat=same-site-cookie-attribute
  return makeCookie(name, value, expires, domain, path, secure, httpOnly, sameSite)

proc genCookie*(name, value: string, expires: DateTime,
                    sameSite: SameSite=Lax, secure = false,
                    httpOnly = false, domain = "", path = ""): string =
  ## Creates a cookie which stores ``value`` under ``name``.
  genCookie(name, value,
            format(expires.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"),
            sameSite, secure, httpOnly, domain, path)

proc getCookie*(request:Request, key:string): string =
  let cookiesStrArr = request.headers["Cookie"].split(";")
  result = ""
  for row in cookiesStrArr:
    let rowArr = row.split("=")
    if rowArr[0] == key:
      result = rowArr[1]

proc sessionStart*(uid:int):string =
  randomize()
  let token = rundStr().secureHash()
  # insert db
  var db = newFlatDb("session.db", false)
  discard db.load()
  db.append(%*{
    "token": $token, "generated_at": $(getTime().toUnix()), "uid": uid
  })
  return $token

const SESSION_TIME = getEnv("SESSION_TIME").string.parseInt

proc addSession*(token:string, key:string, val:string) =
  var db = newFlatDb("session.db", false)
  discard db.load()
  let session = db.queryOne(equal("token", token))
  if isNil(session):
    raise newException(Error403, "CSRF verification failed.")
  # check timeout
  let generatedAt = session["generated_at"].getStr.parseInt
  if getTime().toUnix() > generatedAt + SESSION_TIME:
    raise newException(Error403, "Session Timeout.")
  # add
  session[key] = %val
  db.flush()

proc removeSession*(token:string) =
  var db = newFlatDb("session.db", false)
  discard db.load()
  let session = db.queryOne(equal("token", token))
  let id = session["_id"].getStr
  db.delete id

proc getSession*(token:string, key:string): string =
  var db = newFlatDb("session.db", false)
  discard db.load()
  let session = db.queryOne(equal("token", token))
  result = ""
  if session.hasKey(key):
    result = session[key].getStr