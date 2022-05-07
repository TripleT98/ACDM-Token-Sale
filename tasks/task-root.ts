let {mint} = require("./mint");
let {addLiq} = require("./createPair");
let {approve} = require("./approve");
let {claim} = require("./claim");
let {stake} = require("./stake");

mint();
addLiq();
approve();
claim();
stake();


module.exports = {

}
