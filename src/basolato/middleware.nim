import strutils
# framework
import base, security, header, controller
# 3rd party
import ./core/core

# framework
export base, security, header, controller.errorRedirect
# 3rd party
export core.request

type Check* = ref object
  status*:bool
  msg*:string


proc catch*(this:Check, error:typedesc=Error500, msg="") =
  if not this.status:
    var newMsg = ""
    if msg.len == 0:
      newMsg = this.msg
    else:
      newMsg = msg
    raise newException(error, newMsg)


# =============================================================================
proc checkCsrfToken*(request:Request):Check =
  result = Check(status:true)
  if request.reqMethod == HttpPost and not request.path.contains("api/"):
    try:
      let token = request.params["csrf_token"]
      discard newCsrfToken(token).checkCsrfTimeout()
    except:
      result = Check(
        status:false,
        msg:getCurrentExceptionMsg()
      )

proc checkApiToken*(request:Request):Check =
  if (request.reqMethod == HttpPost or request.reqMethod == HttpPut or
        request.reqMethod == HttpPatch or request.reqMethod == HttpDelete) and
        request.path.contains("api/"):
    result = Check(status:true)

proc checkAuthToken*(request:Request):Check =
  result = Check(status:true)
  let cookie = newCookie(request)
  if cookie.hasKey("session_id"):
    try:
      let sessionId = cookie.get("session_id")
      if sessionId.len == 0:
        raise newException(Exception, "")
      if not checkSessionIdValid(sessionId):
        raise newException(Exception, "")
    except:
      result = Check(
        status:false,
        msg:getCurrentExceptionMsg()
      )

proc redirect*(url:string) =
  raise newException(Error302, url)
