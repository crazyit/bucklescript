[@@@bs.config{bs_class_type = true }]


type  x = < say : int -> int >




let f  (u : x ) = u # say 32

(* let f_js u = u##say 32 [@fn] *)

let suites = Mt.[
  "caml_obj", (fun _ -> Eq (33, f (object method say x = 1 + x end)));
  (* "js_obj", ( *)
  (* Eq(34, f_js [%bs.obj{ say = fun [@fn]  x -> x + 2 } ])) *)
]

;; Mt.from_pair_suites __FILE__ suites

(* class type say = object  *)
(*     method say : int -> int *)
(* end *)
(* create real js object with [this] semantics *)
(* fun _ -> let module N =  *)
(*     struct *)
(*       external mk : say:'a -> say Js.t = ""[@@bs.obj]  *)
(*     end  *)
(*   in  *)
