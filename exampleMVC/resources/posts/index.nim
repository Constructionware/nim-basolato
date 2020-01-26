import json
import ../../../src/basolato/view
import ../base

proc indexHtmlImpl(posts:seq[JsonNode]):string = tmpli html"""
$for post in posts {
  <div class="post">
      <div class="date">
        <p>published: $(post["published_date"].get)</p>
      </div>
    <h2><a href="/posts/$(post["id"].get)">$(post["title"].get)</a></h2>
    <p>$(post["text"].get)</p>
  </div>  
}
"""

proc indexHtml*(auth:Auth, posts:seq[JsonNode]): string =
  baseHtml(auth, indexHtmlImpl(posts))
