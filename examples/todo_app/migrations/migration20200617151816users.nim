import json, strformat
import ../../../src/basolato/baseEnv
import allographer/schema_builder
import allographer/query_builder
import faker
import bcrypt

proc migration20200617151816users_todo*() =
  schema([
    table("users", [
      Column().increments("id"),
      Column().string("name"),
      Column().string("email"),
      Column().string("password"),
      Column().timestamps()
    ]),
    table("todo", [
      Column().increments("id"),
      Column().string("todo"),
      Column().foreign("user_id").reference("id").on("users").onDelete(SET_NULL)
    ])
  ])

  var users = newSeq[JsonNode]()
  let fake = newFaker("ja_JP")
  for i in 1..5:
    users.add(%*{
      "name": fake.name(),
      "email": &"user{i}@gmail.com",
      "password": hash( &"user{i}", SALT)
    })
  RDB().table("users").insert(users)
