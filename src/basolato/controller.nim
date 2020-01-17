import json, os, httpcore, httpcore
import jester
import base


export httpcore, base, jester.request, Request

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


proc redirect*(url:string): Response =
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

# load html
proc html*(r_path:string):string =
  ## arg r_path is relative path from /resources/
  block:
    let path = getCurrentDir() & "/resources/" & r_path
    let f = open(path, fmRead)
    result = $(f.readAll)
    defer: f.close()
