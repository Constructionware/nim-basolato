import ../../src/basolato/middleware
import ../../src/basolato/routing
import ../../src/basolato/security
from custom_headers_middleware import corsHeader

template before_framework*() =
  echo "=== framework middleware"
  checkCsrfToken(request).catch()
  checkAuthToken(request).catch(Error301, "/")
  if request.reqMethod == HttpOptions:
    route(render(""), [corsHeader()])
