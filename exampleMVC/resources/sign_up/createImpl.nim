#? stdtmpl | standard
#import json
#import ../../../src/basolato/view
#import ../base
#proc createHtmlImpl*(name:string, email:string, errors:JsonNode): string =
<h2>Sign Up</h2>
#if errors.hasKey("general"):
  <p style="background-color: deeppink">${errors["general"].getStr}</p>
#end if
<form method="post">
  ${csrfToken()}
  <div>
    <p>name</p>
    #if errors.hasKey("name"):
      <ul>
        #for row in errors["name"]:
          <li>${row.get}</li>
        #end for
      </ul>
    #end if
    <p><input type="text" value="$name" name="name"></p>
  </div>
  <div>
    <p>email</p>
    #if errors.hasKey("email"):
      <ul>
        #for row in errors["email"]:
          <li>${row.get}</li>
        #end for
      </ul>
    #end if
    <p><input type="text" value="$email" name="email"></p>
  </div>
  <div>
    <p>password</p> 
    #if errors.hasKey("password"):
      <ul>
        #for row in errors["password"]:
          <li>${row.get}</li>
        #end for
      </ul>
    #end if
    <p><input type="password" name="password"></p>
  </div>
  <button type="submit">create</button>
</form>
