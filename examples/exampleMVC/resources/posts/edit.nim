import json
# framework
import ../../../src/basolato/view
import ../base

proc editHtmlImpl*(id:int, title:string, text:string, errors:JsonNode):string = tmpli html"""
<h2>Edit Post</h2>
<form method="post">
  $(csrfToken())
  <div>
    <p>Title</p>
    $if errors.hasKey("title") {
      <ul>
        $for row in errors["title"] {
          <li>$row</li>
        }
      </ul>
    }
    <p><input type="text" value="$title" name="title"></p>
  </div>
  <div>
    <p>Text</p>
    $if errors.hasKey("text") {
      <ul>
        $for row in errors["text"] {
          <li>$row</li>
        }
      </ul>
    }
    <textarea name="text">$text</textarea>
  </div>
  <button type="submit">create</button>
</form>
"""

proc editHtml*(auth:Auth, id:int, title="", text="", errors=newJObject()):string =
  baseHtml(auth, editHtmlImpl(id, title, text, errors))