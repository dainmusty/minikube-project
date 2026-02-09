const express = require("express");
const app = express();
const path = require("path");

app.use(express.static("public")); // serve static files

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public/index.html"));
});

app.listen(3000, () => {
  console.log("Fonapp listening on port 3000");
});
