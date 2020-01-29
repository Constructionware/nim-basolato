from strutils import join
import ../../src/basolato/middleware

proc customHeader*():Headers =
  var headers: Headers
  headers.add(("Middleware-Header-Key1", "Middleware-Header-Val1"))
  headers.add(("Middleware-Header-Key2", ["val1", "val2", "val3"].join(", ")))

proc corsHeader*(): Headers =
  var allowedMethods = @[
    "OPTIONS",
    "GET",
    "POST",
    "PUT",
    "DELETE"
  ]

  var allowedHeaders = @[
    "X-login-id",
    "X-login-token"
  ]

  var headers: Headers
  headers.add(("Cache-Control", "no-cache"))
  headers.add(("Access-Control-Allow-Origin", "*"))
  headers.add(("Access-Control-Allow-Methods", allowedMethods.join(", ")))
  headers.add(("Access-Control-Allow-Headers", allowedHeaders.join(", ")))


proc secureHeader*(): Headers =
  let h = @[
    ("Strict-Transport-Security", ["max-age=63072000", "includeSubdomains"].join(", ")),
    ("X-Frame-Options", "SAMEORIGIN"),
    ("X-XSS-Protection", ["1", "mode=block"].join(", ")),
    ("X-Content-Type-Options", "nosniff"),
    ("Referrer-Policy", ["no-referrer", "strict-origin-when-cross-origin"].join(", ")),
    ("Cache-control", ["no-cache", "no-store", "must-revalidate"].join(", ")),
    ("Pragma", "no-cache"),
  ]
  var headers: Headers
  for row in h:
    headers.add(row)
  return headers
