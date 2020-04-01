import json, re, tables, strformat, strutils, unicode
from net import isIpAddress

type Validation* = ref object


proc email(value:string):seq[string] =
  var r = newSeq[string]()
  if value.len == 0:
    r.add("this field is required")
  if not value.match(re"\A[\w+\-.]+@[a-zA-Z\d\-]+(\.[a-zA-Z\d\-]+)*\.[a-zA-Z]+\Z"):
    r.add("invalid form of email")
  return r

proc email*(this:Validation, value:string):bool =
  if email(value).len > 0:
    return false
  else:
    return true

proc domain(value:string):seq[string] =
  var r = newSeq[string]()
  block:
    let fqdn = re"^(([a-z0-9]{1,2}|[a-z0-9][a-z0-9-]{0,61}[a-z0-9])\.)*([a-z0-9]{1,2}|[a-z0-9][a-z0-9-]{0,61}?[a-z0-9])$"
    let addr4 = re"(([01]?[0-9]{1,2}|2(?:[0-4]?[0-9]|5[0-5]))\.){3}([01]?[0-9]{1,2}|2([0-4]?[0-9]|5[0-5]))"
    let addr4Start = re"^(([01]?[0-9]{1,2}|2([0-4]?[0-9]|5[0-5]))\.){3}([01]?[0-9]{1,2}|2([0-4]?[0-9]|5[0-5]))$"
    if value.len == 0 or value.len > 255:
      r.add("domain length is 0")
    if not value.startsWith("["):
      if not (not value.match(addr4) and value.match(fqdn)):
        r.add("invalid domain format")
      elif value.find(re"\.[0-9]$|^[0-9]+$") > -1:
        r.add("the last label of domain should not number")
      else:
        break
    if not value.endsWith("]"):
      r.add("domain lacks ']'")
    var value = value
    value.removePrefix("[")
    value.removeSuffix("]")
    if value.match(addr4Start):
      if value != "0.0.0.0":
        break
      else:
        r.add("domain 0.0.0.0 is invalid")
    if value.endsWith("::"):
      r.add("IPv6 should not end with '::'")
    var v4_flg = false
    var last = ""
    try:
      last = value.rsplit(":", maxsplit=1)[^1]
    except:
      r.add("invalid domain")
    if last.match(addr4):
      if value == "0.0.0.0":
        r.add("domain 0.0.0.0 is invalid")
      value = value.replace(last, "0:0")
      v4_flg = true
    var oc:int
    if value.contains("::"):
      oc = 8 - value.count(":")
      if oc < 1:
        r.add("8 blocks is required for IPv6")
      var ocStr = "0:"
      value = value.replace("::", &":{ocStr.repeat(oc)}")
      if value.startsWith(":"):
        value = &"0{value}"
      if value.endsWith(":"):
        value = &"{value}0"
    var elems = value.split(":")
    if elems.len != 8:
      r.add("invalid IP address")
    var res = 0
    for i, a in elems:
      if a.len > 4:
        r.add("each blick of IP address should be shorter than 4")
      try:
        res += a.parseHexInt shl ((7 - i) * 16)
      except:
        r.add("invalid IPv6 address")
    if not (res != 0 and (not v4_flg or res shr 32 == 0xffff)):
      r.add("invalid IPv4-Mapped IPv6 address")
  return r

proc domain*(this:Validation, value:string):bool =
  if domain(value).len > 0:
    return false
  else:
    return true

proc strictEmail(value:string):seq[string] =
  var r = newSeq[string]()
  block:
    let valid = "abcdefghijklmnopqrstuvwxyz1234567890!#$%&\'*+-/=?^_`{}|~"
    if value.len == 0:
      r.add("invalid email format 1")
    var value = value.toLowerAscii()
    if not value.contains("@"):
      r.add("email should have '@'")
    var i:int
    if value.startsWith("\""):
      i = 1
      while i < min(64, value.len):
        if (valid & "()<>[]:;@,. ").contains(value[i]):
          i.inc()
          continue
        if $value[i] == "\\":
          if value[i+1..^1].len > 0 and (valid & """()<>[]:;@,.\\" """).contains($value[i+1]):
            i.inc(2)
            continue
          r.add("invalid email format 2")
        if value[i] == '"':
          break
      if i == 64:
        i.dec()
      if not (value[i+1..^1].len > 0 and $value[i+1] == "@"):
        r.add("invalid email local-part")
      r = r & domain(value[i+2..^1])
    else:
      i = 0
      while i < min(64, value.len):
        if valid.contains(value[i]):
          i.inc()
          continue
        if $value[i] == ".":
          if i == 0 or value[i+1..^1].len == 0 or ".@".contains(value[i+1]):
            r.add("invalid email local-part")
          i.inc()
          continue
        if $value[i] == "@":
          if i == 0:
            r.add("email has no local-part")
          i.dec()
          break
        r.add("email includes invalid char")
      if i == 64:
        i.dec
      if not (value[i+1..^1].len > 0 and "@".contains(value[i+1])):
        r.add("email local-part should be shorter than 64")
      r = r & domain(value[i+2..^1])
  return r

proc strictEmail*(this:Validation, value:string):bool =
  if strictEmail(value).len > 0:
    return false
  else:
    return true

proc equals(sub:any, target:any):seq[string] =
  var r = newSeq[string]()
  if sub != target:
    r.add(&"{$sub} should be {$target}")
  return r

proc equals*(this:Validation, sub:any, target:any):bool =
  if equals(sub, target).len > 0:
    return false
  else:
    return true

proc gratorThan(sub, target:int|float):seq[string] =
  var r = newSeq[string]()
  if sub <= target:
    r.add(&"{$sub} should be grator than {$target}")
  return r

proc gratorThan*(this:Validation, sub, target:int|float):bool =
  if gratorThan(sub, target).len > 0:
    return false
  else:
    return true

proc inRange(value, min, max:int|float):seq[string] =
  var r = newSeq[string]()
  block:
    if value < min or max < value:
      r.add(&"{value} should be in range between {min} and {max}")
  return r

proc inRange*(this:Validation, value, min, max:int|float):bool =
  if inRange(value, min, max).len > 0:
    return false
  else:
    return true

proc ip*(this:Validation, value:string):bool =
  if domain(&"[{value}]").len > 0:
    return false
  else:
    return true

proc lessThan(sub, target:int|float):seq[string] =
  var r = newSeq[string]()
  if sub >= target:
    r.add(&"{sub} should be less than {target}")

proc lessThan*(this:Validation, sub, target:int|float):bool =
  if lessThan(sub, target).len > 0:
    return false
  else:
    return true

proc numeric(value:string):seq[string] =
  var r = newSeq[string]()
  try:
    let _ = value.parseFloat
  except:
    r.add(&"{value} should be numeric")
  return r

proc numeric*(this:Validation, value:string):bool =
  if numeric(value).len > 0:
    return false
  else:
    return true

proc password(value:string):seq[string] =
  var r = newSeq[string]()
  if value.len == 0:
    r.add("this field is required")

  if value.len < 8:
    r.add("password needs at least 8 chars")

  if not value.match(re"(?=.*?[a-z])(?=.*?[A-Z])(?=.*?\d)[!-~a-zA-Z\d]*"):
    r.add("invalid form of password")
  return r

proc password*(this:Validation, value:string):bool =
  if password(value).len > 0:
    return false
  else:
    return true
