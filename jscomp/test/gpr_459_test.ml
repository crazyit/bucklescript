[@@@bs.config{non_export=true}]

let suites :  Mt.pair_suites ref  = ref []
let test_id = ref 0
let eq loc x y = 
  incr test_id ; 
  suites := 
    (loc ^" id " ^ (string_of_int !test_id), (fun _ -> Mt.Eq(x,y))) :: !suites



let uu = [%bs.obj{
  _'x_ = 3;

} ]

let uu2 = [%bs.obj{
  then_ = 1;
  catch = 2;
  _'x_ = 3 
}]

let hh = uu##_'x_

let () = eq __LOC__ hh 3 

let () = 
  eq __LOC__ (1,2,3) (uu2##then_, uu2##catch, uu2##_'x_)

let () = Mt.from_pair_suites __FILE__ !suites
