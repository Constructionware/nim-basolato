import json, tables, macros, strformat, strutils, httpcore, flatdb, times, os, options
import jester
import htmlgen
import base, logger
from middleware import checkCsrfToken

export jester, base


template route*(rArg: Response) =
  block:
    let r = rArg
    var newHeaders = r.headers
    case r.responseType:
    of String:
      newHeaders.add(("Content-Type", "text/html;charset=utf-8"))
    of Json:
      newHeaders.add(("Content-Type", "application/json"))
      r.bodyString = $(r.bodyJson)
    of Redirect:
      logger($r.status & &"  {request.reqMethod}  {request.ip}  {request.path}")
      newHeaders.add(("Location", r.url))
      resp r.status, newHeaders, ""

    if r.status == Http200:
      logger($r.status & &"  {request.reqMethod}  {request.ip}  {request.path}")
      logger($newHeaders)
    elif r.status.is4xx() or r.status.is5xx():
      echoErrorMsg($r.status & &"  {request.reqMethod}  {request.ip}  {request.path}")
      echoErrorMsg($newHeaders)
    resp r.status, newHeaders, r.bodyString

# =============================================================================

# TODO after pull request mergeed https://github.com/dom96/jester/pull/234
# proc joinHeader(headers:openArray[seq[tuple]]): seq[tuple[key,val:string]] =
proc joinHeader(headers:openArray[seq[tuple]]): seq[tuple[key,value:string]] =
  ## join seq and children tuple if each headers have same key in child tuple
  ##
  ## .. code-block:: nim
  ##    let t1 = @[("key1", "val1"),("key2", "val2")]
  ##    let t2 = @[("key1", "val1++"),("key3", "val3")]
  ##    let t3 = joinHeader([t1, t2])
  ##
  ##    echo t3
  ##    >> @[
  ##      ("key1", "val1, val1++"),
  ##      ("key2", "val2"),
  ##      ("key3", "val3"),
  ##    ]
  ##
  var tmp:seq[tuple[key,value:string]]
  var tmp_tbl = tmp.toOrderedTable
  for header in headers:
    let header_tbl = header.toOrderedTable
    for key, value in header_tbl.pairs:
      if tmp_tbl.hasKey(key):
        tmp_tbl[key] = [tmp_tbl[key], header_tbl[key]].join(", ")
      else:
        tmp_tbl[key] = header_tbl[key]
  var result: seq[tuple[key,value:string]]
  for key, val in tmp_tbl.pairs:
    result.add((key:key, value:val))
  return result


template route*(rArg:Response,
                headers:openArray[seq[tuple]]) =
  block:
    let r = rArg
    # TODO after pull request mergeed https://github.com/dom96/jester/pull/234
    # var newHeaders: seq[tuple[key,val:string]]
    var newHeaders: seq[tuple[key,value:string]]
    newHeaders = joinHeader(headers)
    case r.responseType:
    of String:
      newHeaders.add(("Content-Type", "text/html;charset=utf-8"))
    of Json:
      newHeaders.add(("Content-Type", "application/json"))
      r.bodyString = $(r.bodyJson)
    of Redirect:
      logger($r.status & &"  {request.reqMethod}  {request.ip}  {request.path}")
      newHeaders.add(("Location", r.url))
      resp r.status, newHeaders, ""

    if r.status == Http200:
      logger($r.status & &"  {request.reqMethod}  {request.ip}  {request.path}")
      logger($newHeaders)
    elif r.status.is4xx() or r.status.is5xx():
      echoErrorMsg($r.status & &"  {request.reqMethod}  {request.ip}  {request.path}")
      echoErrorMsg($newHeaders)
    resp r.status, newHeaders, r.bodyString


proc response*(arg:ResponseData):Response =
  if not arg[4]: raise newException(Error404, "")
  # ↓ TODO DELETE after pull request mergeed https://github.com/dom96/jester/pull/234
  var newHeader:seq[tuple[key, value:string]]
  for header in arg[2].get(@[("", "")]):
    newHeader.add((key:header.key , value:header.val))
  # ↑
  return Response(
    status: arg[1],
    headers: newHeader,
    # headers: arg[2].get, # TODO after pull request mergeed https://github.com/dom96/jester/pull/234
    body: arg[3],
    match: arg[4]
  )

# =============================================================================

proc prodErrorPage(status:HttpCode): string =
  return html(head(title($status)),
            body(h1($status),
                "<hr/>",
                p(&"👑Nim Basolato {basolatoVersion}"),
                style = "text-align: center;"
            ),
            xmlns="http://www.w3.org/1999/xhtml")

proc devErrorPage(status:HttpCode, error: string): string =
  return html(
          head(title("Basolato Dev Error Page")),
          body(
            h1($status),
            h2("An error has occured in one of your routes."),
            p(b("Detail: ")),
            code(pre(error)),
            "<hr/>",
            p(&"👑Nim Basolato {basolatoVersion}", style = "text-align: center;"),
          ),
          xmlns="http://www.w3.org/1999/xhtml"
        )


template http404Route*() =
  if not request.path.contains("favicon"):
    echoErrorMsg(&"{$Http404}  {request.ip}  {request.path}")
  resp Http404, prodErrorPage(Http404)

macro createHttpCodeError():untyped =
  var strBody = ""
  for num in httpCodeArray:
    strBody.add(fmt"""
of "Error{num.repr}":
  return Http{num.repr}
""")
  return parseStmt(fmt"""
case $exception.name
{strBody}
else:
  return Http500
""")

proc checkHttpCode(exception:ref Exception):HttpCode =
  ## Generated by macro createHttpCodeError
  ## List is httpCodeArray
  ## .. code-block:: nim
  ##   case $exception.name
  ##   of Error505:
  ##     return Http505
  ##   of Error504:
  ##     return Http504
  ##   of Error503:
  ##     return Http503
  ##   .
  ##   .
  createHttpCodeError

template exceptionRoute*() =
  defer: GCunref exception
  let status = checkHttpCode(exception)
  echoErrorMsg($r.status & &"  {request.reqMethod}  {request.ip}  {request.path}  {exception.msg}")
  when not defined(release):
    resp status, devErrorPage(status, exception.msg)
  else:
    resp status, prodErrorPage(status)

# =============================================================================

template middleware*(procs:varargs[Response]) =
  for p in procs:
    if p == nil:
      # echo getCurrentExceptionMsg()
      discard
    else:
      route(p)
      break
