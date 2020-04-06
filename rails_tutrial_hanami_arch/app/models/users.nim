import allographer/query_builder

proc show*(this:User, id:int):JsonNode =
  echo this.db.get()

proc save*(this:User) =
  this.db.insert(%*{
    "name": this.name.get,
    "email": this.email.get,
    "password_digest": this.password.get
  })