
[@@@bs.config{bs_class_type = true }]
class type ['a] case = object 
  method case : int -> 'a 
  method case_set : int -> 'a -> unit 
end




(* let f (x : [%bs.obj: < case : int ->  'a ;  *)
(*             case_set : int ->  int -> unit ; *)
(*             .. > [@fn] ] ) *)
(*  =  *)
(*   x ## case_set 3 2 ; *)
(*   x ## case 3  *)


let ff (x : int case  Js.t)
 = 
  x##case_set 3 2 ;
  x##case 3 


type 'a return = int -> 'a [@fn]
let h (x : 
         [%bs.obj:< cse : (int -> 'a return  ); .. >  [@fn] ]) = 
  let cse = x##cse in
  let a = cse 3 [@fn] in 
  a 2 [@fn]   


type x_obj =  
  [%bs.obj: < 
    cse : int ->  int ; 
    cse_st : int -> int -> unit ;
  >  [@fn] ]

let f_ext 
    (x : x_obj)
 = 
  let v = x ## cse_st in v 3 2 [@fn] ;
  let cse = x ## cse in cse  3 [@fn]


type 'a h_obj = 
  [%bs.obj: < 
    cse : int ->  'a return 
  > [@fn] ]

let h_ext  (x : 'a h_obj) = 
  let cse = x ##cse in
  let  a =  cse 3 [@fn] in 
  a 2 [@fn] 
