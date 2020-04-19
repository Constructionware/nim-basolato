import json
import ../value_objects
import user_entity
import user_repository_interface

type UserService* = ref object
  repository:UserRepository

proc newUserService*():UserService =
  return UserService(
    repository:newIUserRepository()
  )


proc show*(this:UserService, id:int):JsonNode =
  let id = newId(id)
  let user = newUser(id)
  return this.repository.show(user)

proc store*(this:UserService, name="", email="", password=""):int =
  let name = newUserName(name)
  let email = newEmail(email)
  let password = newPassword(password)
  let user = newUser(name=name, email=email, password=password)
  let id = this.repository.store(user)
  let userId = newId(id).get()
  return userId

proc login*(this:UserService, email="", password="") =
  let email = newEmail(email)
  let password = newPassword(password)
  let user = newUser(email=email, password=password)
  let hashedPassword = this.repository.getPasswordByEmail(user)
  if hashedPassword.len == 0:
    raise newException(Exception, "Invalid email")
  if not user.isMatchPassword(hashedPassword):
    raise newException(Exception, "password is not match")
