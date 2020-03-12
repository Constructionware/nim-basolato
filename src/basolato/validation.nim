import json, re, tables, strformat, strutils
from jester import Request, params
import allographer/query_builder


type
  Validation* = ref object
    params*: Table[string, string]
    errors*: JsonNode # JObject


proc validate*(request: Request): Validation =
  Validation(
    params: request.params,
    errors: newJObject()
  )


proc putValidate*(this: Validation, key: string, error: JsonNode) =
  if isNil(this.errors):
    this.errors = %{key: error}
  else:
    this.errors[key] = error

proc putValidate*(this: Validation, key: string, msg: string) =
  if isNil(this.errors):
    this.errors = %*{key: [msg]}
  elif this.errors.hasKey(key):
    this.errors[key].add(%(msg))
  else:
    this.errors[key] = %[(msg)]

# =============================================================================

proc accepted*(this: Validation, key: string, val = "on"): Validation =
  if this.params.hasKey(key):
    if this.params[key] != val:
      this.putValidate(key, &"{key} should be accespted")
  return this

proc contains*(this: Validation, key: string, val: string): Validation =
  if this.params.hasKey(key):
    if not this.params[key].contains(val):
      this.putValidate(key, &"{key} should contain {val}")
  return this

proc email*(this: Validation, key = "email"): Validation =
  var error = newJArray()
  if this.params[key].len == 0:
    error.add(%"this field is required")

  if not this.params[key].match(re"\A[\w+\-.]+@[a-zA-Z\d\-]+(\.[a-zA-Z\d\-]+)*\.[a-zA-Z]+\Z"):
    error.add(%"invalid form of email")

  if error.len > 0:
    this.putValidate(key, error)

  return this

proc strictEmail*(this: Validation, key = "email"): Validation =
  var error = newJArray()
  var email = this.params[key]
  var local = ""
  var domain = ""

  try:
    if email.len == 0:
      raise newException(Exception, "this field is required")

    if not email.contains("@"):
      raise newException(Exception, "email need '@'")

    # if local is wrappd by double wuote
    if email.find(re"""".+"@""") > -1:
      domain = email.replace(re"""".+"@""")
      local = email.findAll(re"""".+"@""")[0]
      # Japanese or Chinese is invalid
      if local.find(re"[^\x01-\x7E]+") > 0:
        raise newException(Exception, "full-width char is invalid")
    else:
      let arr = email.split("@")
      local = arr[0]
      domain = arr[1]

      if email.cstring.len > 254:
        raise newException(Exception, "email should shorter than 254")

      if local.cstring.len > 64:
        raise newException(Exception, "invalid form of email")

      if local.startsWith(".") or local.endsWith("."):
        raise newException(Exception, "invalid form of email")

      if local.match(re".*\.{2}.*"):
        raise newException(Exception, "invalid form of email")

      if local.find(re"[^a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+") > -1:
        raise newException(Exception, "invalid form of email")

    if domain.match(re"\[.*\]"):
      # domain is IP address
      if not domain.match(re"\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\]"):
        raise newException(Exception, "invalid form of email")
    else:
      # domain is string

      if not domain.match(re"[a-zA-Z]+"):
        # if no alphabet
        raise newException(Exception, "invalid form of email")

      if domain.match(re".*\.{2}.*"):
        ## ..
        raise newException(Exception, "invalid form of email")

      var domainArr = domain.split(".")
      for label in domainArr:
        if label.cstring.len > 63:
          raise newException(Exception, "invalid form of email")

        if label.find(re"^[^a-zA-Z0-9]") > -1 or
        label.find(re"[^a-zA-Z0-9]$") > -1:
          # label cannot start / end of symbol
          raise newException(Exception, "invalid form of email")

        if label.find(re"[^a-zA-Z0-9\-]+") > -1:
          raise newException(Exception, "invalid form of email")

        if label.find(re"[^a-zA-Z0-9]+") > -1:
          raise newException(Exception, "invalid form of email")

      if domainArr[^1].match(re"[0-9]{1}"):
        # end of domain should not be number
        raise newException(Exception, "invalid form of email")
  except:
    error.add(%(getCurrentExceptionMsg()))

  if error.len > 0:
    echo local
    echo email
    this.putValidate(key, error)
  else:
    # echo local
    # echo domain
    # echo email
    discard

  return this

proc equals*(this: Validation, key: string, val: string): Validation =
  if this.params.hasKey(key):
    if this.params[key] != val:
      this.putValidate(key, &"{key} should be {val}")
  return this

proc exists*(this: Validation, key: string): Validation =
  if not this.params.hasKey(key):
    this.putValidate(key, &"{key} should exists in request params")
  return this

proc gratorThan*(this: Validation, key: string, val: float): Validation =
  if this.params.hasKey(key):
    if this.params[key].parseFloat <= val:
      this.putValidate(key, &"{key} should be grator than {val}")
  return this

proc inRange*(this: Validation, key: string, min: float,
    max: float): Validation =
  if this.params.hasKey(key):
    let val = this.params[key].parseFloat
    if val < min or max < val:
      this.putValidate(key, &"{key} should be in range between {min} and {max}")
  return this

proc ip*(this: Validation, key: string): Validation =
  if this.params.hasKey(key):
    if not this.params[key].match(re"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"):
      this.putValidate(key, &"{key} should be a form of IP address")
  return this

proc isIn*(this: Validation, key: string, vals: openArray[
    int|float|string]): Validation =
  if this.params.hasKey(key):
    var count = 0
    for val in vals:
      if this.params[key] == $val:
        count.inc
    if count == 0:
      this.putValidate(key, &"{key} should be in {vals}")
  return this

proc lessThan*(this: Validation, key: string, val: float): Validation =
  if this.params.hasKey(key):
    if this.params[key].parseFloat >= val:
      this.putValidate(key, &"{key} should be less than {val}")
  return this

proc numeric*(this: Validation, key: string): Validation =
  if this.params.hasKey(key):
    try:
      let _ = this.params[key].parseFloat
    except:
      this.putValidate(key, &"{key} should be numeric")
  return this

proc oneOf*(this: Validation, keys: openArray[string]): Validation =
  var count = 0
  for key, val in this.params:
    if keys.contains(key):
      count.inc
  if count == 0:
    this.putValidate("oneOf", &"at least one of {keys} is required")
  return this

proc password*(this: Validation, key = "password"): Validation =
  var error = newJArray()
  if this.params[key].len == 0:
    error.add(%"this field is required")

  if this.params[key].len < 8:
    error.add(%"password needs at least 8 chars")

  if not this.params[key].match(re"(?=.*?[a-z])(?=.*?[A-Z])(?=.*?\d)[!-~a-zA-Z\d]*"):
    error.add(%"invalid form of password")

  if error.len > 0:
    this.putValidate(key, error)

  return this

proc required*(this: Validation, keys: openArray[string]): Validation =
  for key in keys:
    if not this.params.hasKey(key) or this.params[key].len == 0:
      this.putValidate(key, &"{key} is required")
  return this

proc unique*(this: Validation, key: string, table: string,
    column: string): Validation =
  if this.params.hasKey(key):
    let val = this.params[key]
    let num = RDB().table(table).where(column, "=", val).count()
    if num > 0:
      this.putValidate(key, &"{key} should be unique")
  return this
