# framework
import base, security, header
from controller import render, redirect, errorRedirect
# 3rd party
import jester except redirect, setCookie

# framework
export base, security, header, render, redirect, errorRedirect
# 3rd party
export jester.request

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
  if request.reqMethod == HttpPost or request.reqMethod == HttpPut or
        request.reqMethod == HttpPatch or request.reqMethod == HttpDelete:
    let token = request.params["csrf_token"]
    try:
      discard newCsrfToken(token).checkCsrfTimeout()
    except:
      result = Check(
        status:false,
        msg:getCurrentExceptionMsg()
      )
  

proc checkAuthTokenValid*(request:Request):Check =
  result = Check(status:true)
  try:
    var sessionId = newCookie(request).get("session_id")
    if sessionId.len > 0:
      discard newAuth(request).getToken()
  except:
    result = Check(
      status:false,
      msg:getCurrentExceptionMsg()
    )


