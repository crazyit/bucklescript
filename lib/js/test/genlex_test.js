// GENERATED CODE BY BUCKLESCRIPT VERSION 0.6.2 , PLEASE EDIT WITH CARE
'use strict';

var Stream = require("../stream");
var Mt     = require("./mt");
var Block  = require("../block");
var Genlex = require("../genlex");
var List   = require("../list");

var lexer = Genlex.make_lexer(/* :: */[
      "+",
      /* :: */[
        "-",
        /* :: */[
          "*",
          /* :: */[
            "/",
            /* :: */[
              "let",
              /* :: */[
                "=",
                /* :: */[
                  "(",
                  /* :: */[
                    ")",
                    /* [] */0
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]);

function to_list(s) {
  var _acc = /* [] */0;
  while(true) {
    var acc = _acc;
    var exit = 0;
    var v;
    try {
      v = Stream.next(s);
      exit = 1;
    }
    catch (exn){
      if (exn === Stream.Failure) {
        return List.rev(acc);
      }
      else {
        throw exn;
      }
    }
    if (exit === 1) {
      _acc = /* :: */[
        v,
        acc
      ];
      continue ;
      
    }
    
  };
}

var suites_000 = /* tuple */[
  "lexer_stream_genlex",
  function () {
    return /* Eq */Block.__(0, [
              /* :: */[
                /* Int */Block.__(2, [3]),
                /* :: */[
                  /* Kwd */Block.__(0, ["("]),
                  /* :: */[
                    /* Int */Block.__(2, [3]),
                    /* :: */[
                      /* Kwd */Block.__(0, ["+"]),
                      /* :: */[
                        /* Int */Block.__(2, [2]),
                        /* :: */[
                          /* Int */Block.__(2, [-1]),
                          /* :: */[
                            /* Kwd */Block.__(0, [")"]),
                            /* [] */0
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ],
              to_list(lexer(Stream.of_string("3(3 + 2 -1)")))
            ]);
  }
];

var suites = /* :: */[
  suites_000,
  /* [] */0
];

Mt.from_pair_suites("genlex_test.ml", suites);

exports.lexer   = lexer;
exports.to_list = to_list;
exports.suites  = suites;
/* lexer Not a pure module */
