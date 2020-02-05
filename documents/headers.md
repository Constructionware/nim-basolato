Headers
===
# Request Header
To get request header, use `request.headers`

middleware/check_login.nim
```nim
import basolato/middleware

proc hasLoginId*(request: Request):Response =
  try:
    let loginId = request.headers["X-login-id"]
  except:
    raise newException(Error403, "Can't get login id")
```

app/controllers/sample_controller.nim
```nim
proc index*(this:SampleController): Response =
  let loginId = this.request.headers["X-login-id"]
```

# Response header
## Type of headers
Type of response header is `seq[tuple[key, val:string]]`
```nim
from strutils import join

proc secureHeader*(): seq =
  return @[
    ("Strict-Transport-Security", ["max-age=63072000", "includeSubdomains"].join(", ")),
    ("X-Frame-Options", "SAMEORIGIN"),
    ("X-XSS-Protection", ["1", "mode=block"].join(", ")),
    ("X-Content-Type-Options", "nosniff"),
    ("Referrer-Policy", ["no-referrer", "strict-origin-when-cross-origin"].join(", ")),
    ("Cache-control", ["no-cache", "no-store", "must-revalidate"].join(", ")),
    ("Pragma", "no-cache"),
  ]
```


## Set headers in routing
You can set custom headers by setting 2nd arg or `route()`  
Procs which return custom headers have to return seq `@[(key, val: string)]`

```nim
import basolato/routing

from config/custom_headers import corsHeader
import app/controllers/SomeController

routes:
  get "/":
    route(SomeController.index(), [corsHeader(request), secureHeader()])
```

To set custom headers for specific URL group, use `after` verb
```nim
after re"/api.*":
  route(response(result), [corsHeader(request), secureHeader()])
extend api, "/api"
```

## Set headers in controller
`headers` proc with method chain with `render` will set custom response header. If same key of header set in `main.nim`, it will be overwitten.
```nim
proc index*(): Response =
  return render("with headers")
    .header("key1", "value1")
    .header("key2", ["a", "b", "c"])
```