Validation
===
[back](../README.md)

Table of Contents

<!--ts-->
   * [Validation](#validation)
      * [sample](#sample)
      * [Custom Validation](#custom-validation)
      * [Available Rules](#available-rules)
         * [accepted](#accepted)
         * [contains](#contains)
         * [email, strictEmail](#email-strictemail)
         * [equals](#equals)
         * [exists](#exists)
         * [gratorThan](#gratorthan)
         * [inRange](#inrange)
         * [ip](#ip)
         * [isIn](#isin)
         * [lessThan](#lessthan)
         * [numeric](#numeric)
         * [oneOf](#oneof)
         * [password](#password)
         * [required](#required)
         * [unique](#unique)

<!-- Added by: jiro4989, at: 2020年  3月 30日 月曜日 08:22:38 JST -->

<!--te-->

Basolato has it's own validation function. It recieves request and check request params.  
There are two validation type. One is used in controller that recieve request and return errors array.
Another is more simple. Recieve value and return `bool`.

# Simple Validation
```
import basolato/validation
```
## Available Rules
### email
```nim
echo Validation().email("sample@example.com")
>> true

echo Validation().email("sample@example")
>> false
```

### domain
```nim
echo Validation().domain("example.com")
>> true

echo Validation().domain("example")
>> false
```

### strictEmail
```nim
echo Validation().strictEmail("sample@example.com")
>> true

echo Validation().strictEmail("sample@example")
>> false
```

### equals
```nim
echo Validation().equals("a", "a")
>> true

echo Validation().equals(1, 2)
>> false
```

### gratorThan
```nim
echo Validation().gratorThan(1.2, 1.1)
>> true

echo Validation().gratorThan(3, 2)
>> false
```

### inRange
```nim
echo Validation().inRange(2, 1, 3)
>> true

echo Validation().gratorThan(1.5, 1, 1.4)
>> false
```

### ip
```nim
echo Validation().ip("12.0.0.1")
>> true

echo Validation().ip("255.255.255.256")
>> false
```

### lessThan
```nim
echo Validation().lessThan(1.1, 1.2)
>> true

echo Validation().lessThan(3, 2)
>> false
```

### numeric
```nim
echo Validation().numeric("1")
>> true

echo Validation().numeric("a")
>> false
```

### password
```nim
echo Validation().password("Password1")
>> true

echo Validation().password("pass")
>> false
```


# Request Validation
```
import basolato/request_validation
```

## sample

Controller
```nim
type SignUpController = ref object
  request:Request
  auth: Auth

proc newSignUpController*(request:Request): SignUpController =
  return SignUpController(
    request: request,
    auth: initAuth(request)
  )

proc store*(this:SignUpController): Response =
  let name = this.request.params["name"]
  let email = this.request.params["email"]
  let password = this.request.params["password"]
  # validation
  let v = this.request.validate()
            .required(["name", "email", "password"])
            .email("email")
            .unique("email", "users", "email")
            .password("password")
  if v.errors.len > 0:
    return render(createHtml(this.auth, name, email, v.errors))
```

View
```html
proc createHtmlImpl(name:string, email:string, errors:JsonNode): string = tmpli html"""
  <form method="post">
    $(csrfToken())
    <div>
      <p>name</p>
      $if errors.hasKey("name") {
        <ul>
          $for error in errors["name"] {
            <li>$error</li>
          }
        </ul>
      }
      <p><input type="text" value="$name" name="name"></p>
    </div>
    .
    .
    .
```

## Custom Validation
You can also create your own validation middleware. It should recieve `RequestValidation` object and return it.  
`putValidate()` proc is useful to create/add error in `RequestValidation` object.

middleware/custom_validate_middleware.nim
```nim
import json, tables
import bcrypt
import allographer/query_builder
import basolato/request_validation

proc checkPassword*(this:RequestValidation, key:string): RequestValidation =
  let password = this.params["password"]
  let response = RDB().table("users")
                  .select("password")
                  .where("email", "=", this.params["email"])
                  .first()
  let dbPass = if response.kind != JNull: response["password"].getStr else: ""
  let hash = dbPass.substr(0, 28)
  let hashed = hash(password, hash)
  let isMatch = compare(hashed, dbPass)
  if not isMatch:
    this.putValidate(key, "password is not match")
  return this
```

## Available Rules

### accepted
This will add errors if not checked in checkbox. Default checked value is `on` and if you want overwrite it, set in arg.

```html
<input type="checkbox" name="sample">
>> If it checked, it return {"sample", "on"}

<input type="checkbox" name="sample2" value="checked">
>> If it checked, it return {"sample2", "checked"}
```

```nim
validate(request)
  .accepted("sample")
  .accepted("sample2", "checked")
```

### contains
This will add errors if value in request doesn't contain a expected string.

```json
{"email": "user1@gmail.com"}
```

```nim
validate(request).contains("email", "user")
```

### email, strictEmail
This will add errors if value is not match a style of email address.  
`strictEmail` supports [RFC5321](https://tools.ietf.org/html/rfc5321) and [RFC5322](https://tools.ietf.org/html/rfc5322) completely. References this Python code https://gist.github.com/frodo821/681869a36148b5214632166e0ad293a9

```json
{"address": "user1@gmail.com"}
```

```nim
validate(request).email("address")
validate(request).strictEmail("address")
```

### equals
This will add errors if value is not same against expectd string.

```json
{"name": "John"}
```

```nim
validate(request).equals("name", "John")
```

### exists
This will add errors if key is not exist in request params.

```json
{"name": "John", "email": "John@gmail.com"}
```

```nim
validate(request).exists("name")
```

### gratorThan
This will add errors if value is not grater/larger than expected value.

```json
{"age": "25"}
```

```nim
validate(request).gratorThan("age", 26)
```

### inRange
This will add errors if value is not in rage of expected value.

```json
{"age": "25"}
```

```nim
validate(request).inRange("age", min=20, max=60)
```

### ip
This will add errors if value is not match a style of IP address.

```json
{"ip_address": "127.0.0.1"}
```

```nim
validate(request).ip("ip_address")
```

### isIn
This will add errors if value is not match for one of expected values.

```json
{"name": "John"}
```

```nim
validate(request).isIn("name", ["John", "Paul", "George", "Ringo"])
```

### lessThan
This will add errors if value is not less/smaller than expected value.

```json
{"age": "25"}
```

```nim
validate(request).gratorThan("age", 24)
```


### numeric
This will add errors if value is not number.

```json
{"num": 36.2}
```

```nim
validate(request).numeric("num")
```

### oneOf
This will add errors if one of expected keys is not present in request.

```json
{"name": "John", "email": "John@gmail.com"}
```

```nim
validate(request).oneOf(["name", "birth_date", "job"])
```

### password
This will add errors if value is not match a style of password.  
It needs at least 8 chars, one upper and lower letter, symbol(ex: @-_?!) is available.

```json
{"pass": "Password1!"}
```

```nim
validate(request).password("pass")
```

### required
This will add errors if all of expected keys is not present in request.

```json
{"name": "John", "email": "John@gmail.com"}
```

```nim
validate(request).required(["name", "email"])
```

### unique
This will add errors if expected value is not unique in database.

table: users

|id|name|email|
|---|---|---|
|1|user1|user1@gmail.com|
|2|user2|user2@gmail.com|
|3|user3|user3@gmail.com|
|4|user4|user4@gmail.com|

```json
{"mail": "user5@gmail.com"}
```

```nim
validate(request).unique("mail", "users", "email")
```
|arg position|example|content|
|---|---|---|
|1|"mail"|response params key|
|2|"users"|RDB table name|
|3|"email"|RDB column name|
