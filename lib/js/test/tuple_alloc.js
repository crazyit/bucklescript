// GENERATED CODE BY BUCKLESCRIPT VERSION 0.6.2 , PLEASE EDIT WITH CARE
'use strict';


var v = [0];

function match_000() {
  v[0] = 0;
  return /* () */0;
}

function match_001() {
  return v[0] = v[0] + 1 | 0;
}

var reset = match_000;

var incr = match_001;

exports.v     = v;
exports.reset = reset;
exports.incr  = incr;
/* No side effect */
