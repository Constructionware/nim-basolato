import json, strformat

import allographer/schema_builder
import allographer/query_builder

proc migration20200331065251users*() =
  schema([
    table("users", [
      Column().increments("id"),
      Column().string("name"),
      Column().string("email"),
      Column().timestamps()
    ])
  ])
