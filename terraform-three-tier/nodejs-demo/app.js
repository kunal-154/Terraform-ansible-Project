var express = require("express");
var app = express();

const PORT = 3000;

app.get('/', (req, res) => {
    return res.send("Hello World. From ansible and terraform");
});

app.listen(PORT, ()=> {
    console.log("Listening on port: " + PORT);
});
