import json, httpcore, strformat, macros
# from jester import HttpCode

# export HttpCode

const httpCodeArray* = [505, 504, 503, 502, 501, 500, 451, 431, 429, 428, 426,
  422, 421, 418, 417, 416, 415, 414, 413, 412, 411, 410, 409, 408, 407, 406,
  405, 404, 403, 401, 400, 307, 305, 304, 303, 302, 301, 300, 206, 205, 204,
  203, 202, 201, 200, 101, 100]

macro createHttpException():untyped =
  var strBody = """type
"""
  for num in httpCodeArray:
    strBody.add(fmt"""  Error{num}* = object of Exception
""")
  return parseStmt(strBody)

type
  Response* = ref object
    status*:HttpCode
    bodyString*: string
    bodyJson*: JsonNode
    responseType*: ResponseType
    headers*: seq[tuple[key, value:string]]
    url*: string

  ResponseType* = enum
    String
    Json
    Redirect

  CsrfError* = object of Exception
  
createHttpException

const basolatoVersion* = "v0.0.1"
