import json
import ../../../../src/basolato/view
import ../layouts/application_view

proc impl(todos:seq[JsonNode], flash:JsonNode):string = tmpli html"""
$for key, val in flash{
  <p style="color: green;">$(val.get)</p>
}
<a href="/logout">logout</a>
<form method="POST">
  $(csrfToken())
  <input type="text" name="todo">
  <button type="submit">add</button>
</form>
  $if todos.len > 0{
    <table>
      $for todo in todos{
        <tr>
          <td>$(todo["todo"].get)</td>
          <td>
            <a href="/todo/$(todo["id"].get)">detail</a>
          </td>
          <td>
            <form method="post" action="/todo/$(todo["id"].get)/delete">
              $(csrfToken())
              <button type="submit">delete</button>
            </form>
          </td>
        </tr>
      }
    </table>
  }
  $else{
    <p>contant not found</p>
  }
"""

proc todoView*(this:View, todos:seq[JsonNode], flash=newJObject()):string =
  let title = "todo"
  return this.applicationView(title, impl(todos, flash))
