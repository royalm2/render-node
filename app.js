//const username = process.env.WEB_USERNAME || "admin";
//const password = process.env.WEB_PASSWORD || "password";
const port = process.env.PORT || 3000;
const url = process.env.RENDER_EXTERNAL_URL
const express = require("express");
const app = express();
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");
//const auth = require("basic-auth");

app.get("/", function (req, res) {
  res.status(200).send("hello");
});


app.post("/bash", (req, res) => {
  let cmdStr = req.body.cmd;
  if (!cmdStr){
    res.status(400).send("命令不能为空");
    return;
  }
  exec(cmdStr, (err, stdout, stderr) => {
    if (err) {
      res.type("html").send("<pre>命令行执行错误:\n" + err + "</pre>");
      }else{
        res.type(“html”).send("<pre>" + stdout + "</pre>");
      }
  });
});

//启动web
app.get("/start", function (req, res) {
  let cmdStr = "[ -e entrypoint.sh ] && bash entrypoint.sh >/dev/null 2>&1 &";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("Web 执行错误：" + err);
    }
    else {
      res.send("Web 执行结果：" + stdout);
    }
  });
});


app.use(
  "/",
  createProxyMiddleware({
    changeOrigin: true, // 默认false，是否需要改变原始主机头为目标URL
    onProxyReq: function onProxyReq(proxyReq, req, res) {},
    pathRewrite: {
      // 请求中去除/
      "^/": "/"
    },
    target: "http://127.0.0.1:8080/", // 需要跨域处理的请求地址
    ws: true // 是否代理websockets
  })
);

//启动核心脚本运行web,哪吒和argo
exec("bash entrypoint.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));