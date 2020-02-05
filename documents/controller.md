Controller
===
[back](../README.md)

## Creating a Controller
Use `ducere` command  
[ducere make controller](./ducere.md#controller)

Resource controllers are controllers that have basic CRUD / resource style methods to them.  
Generated controller is resource controller.

```nim
from strutils import parseInt
# framework
import basolato/controller


type SampleController* = ref object of Controller

proc newSampleController(request:Request):SampleController =
  return SampleController.newController(request)


proc index*(this:SampleController):Response =
  return render("index")

proc show*(this:SampleController, idArg:string):Response =
  let id = idArg.parseInt
  return render("show")

proc create*(this:SampleController):Response =
  return render("create")

proc store*(this:SampleController):Response =
  return render("store")

proc edit*(this:SampleController, idArg:string):Response =
  let id = idArg.parseInt
  return render("edit")

proc update*(this:SampleController):Response =
  return render("update")

proc destroy*(this:SampleController, idArg:string):Response =
  let id = idArg.parseInt
  return render("destroy")

```
## Constructor & DI
main.nim
```nim
routes
  get "/": newSampleController(request).index()

```

app/controllers/sample_controller.nim
```nim
import ../models/users

type SampleController = ref object of Controller
  user:User

proc newSampleController*(request:Request): SampleController =
  var sampleController = SampleController.newController(request)
  this.user = newUser()
  return this

proc index*(this:SampleController): Response =
  this.request # Request
  this.auth # Auth
  this.user # User(DB model)
```
DI(Dependency Injection) is a technique whereby one object supplies the dependencies of another object.  
In this example, `request`, `auth` and `user` userd in controller action method is initialized in `newSampleController` constructor.  
When you define controller object extends `Controller`, `request` and `auth` is initialized. You can add object by yourself.(ex: DB model object)




## Returning string
If you set string in `render` proc, controller returns string.
```nim
proc index*(): Response =
  return render("index")
```

## Returning HTML file
If you set html file path in `html` proc, controller returns HTML.  
This file path should be relative path from `resources` dir

```nim
proc index*(): Response =
  return render(html("sample/index.html"))

>> display /resources/sample/index.html
```

## Returning template
Call template proc with args in `render` will return template

resources/sample/index.nim
```nim
import tampleates

proc indexHtml(name:string):string = tmpli html"""
<h1>index</h1>
<p>$name</p>
"""
```
main.nim
```nim
import resources/sample/index

proc index*(): Response =
  return render(indexHtml("John"))
```

## Returning JSON
If you set JsonNode in `render` proc, controller returns JSON.

```nim
proc index*(): Response =
  return render(
    %*{"key": "value"}
  )
```

## Response status
Put response status code arge1 and response body arge2
```nim
proc index*(): Response =
  return render(HTTP500, "It is a response body")
```

[Here](https://nim-lang.org/docs/httpcore.html#10) is the list of response status code available.  
[Here](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes) is a experiment of HTTP status code
