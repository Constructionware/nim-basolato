import ../../src/shiotsuchi/controller

proc middlewar_header*():Response =
  return render("ミドルウェアありヘッダーあり").header("Header-Status", "ヘッダーあり")
                                            .header("key1", "value1")
                                            .header("key2", "value2")
                                            .header("key3", ["a", "b", "c"])

proc withHeader*():Response =
  return render("ミドルウェアなしヘッダーあり").header("Header-Status", "ヘッダーあり")
                                            .header("key1", "value1")
                                            .header("key2", "value2")
                                            .header("key3", ["a", "b", "c"])

proc withMiddleware*():Response =
  return render("ミドルウェアありヘッダーなし")

proc nothing*():Response =
  return render("ミドルウェアなしヘッダーなし")
