(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)

open Ast_helper 

let js_obj_type_id () = 
  if Js_config.get_env () = Browser then
    Ast_literal.Lid.pervasives_js_obj
  else Ast_literal.Lid.js_obj 
    
let curry_type_id () = 
  if Js_config.get_env () = Browser then 
     Ast_literal.Lid.pervasives_fn
  else 
    Ast_literal.Lid.js_fn

let mk_args ~loc n tys = 

  Typ.variant ~loc 
    [ Rtag ("Args_" ^ string_of_int n, [], (tys = []),  tys)] Closed None

let lift_curry_type  ~loc args result  = 
  let xs =
    match args with 
    | [ ] -> [mk_args 0  ~loc [] ; result ]
    | [ x ] -> [ mk_args ~loc 1 [x] ; result ] 
    | _ -> 
      [mk_args ~loc (List.length args ) [Typ.tuple ~loc args] ; result ]
  in 
  Typ.constr ~loc {txt = curry_type_id (); loc} xs

let lift_js_type ~loc  x  = 
  Typ.constr ~loc {txt = js_obj_type_id (); loc} [x]

let meth_type_id () = 
  if Js_config.get_env () = Browser then 
    Ast_literal.Lid.pervasives_meth_callback
  else 
    Ast_literal.Lid.js_meth_callback


let arrow = Typ.arrow



let lift_js_meth_callback ~loc (obj,meth) 
  = Typ.constr ~loc {txt = meth_type_id () ; loc} [obj; meth]

let down_with_name ~loc obj name =
  let downgrade ~loc () = 
    let var = Typ.var ~loc "a" in 
    Ast_comb.arrow_no_label ~loc
      (lift_js_type ~loc var) var
  in
  Ast_comb.local_extern_cont loc  
    ~pval_prim:["js_unsafe_downgrade"] 
    ~pval_type:(downgrade ~loc ())
    ~local_fun_name:"cast" 
    (fun down -> Exp.send ~loc (Exp.apply ~loc down ["", obj]) name  )

let gen_fn_run loc arity fn args  : Parsetree.expression_desc = 
  let pval_prim = ["js_fn_run" ; string_of_int arity]  in
  let fn_type, args_type, result_type = Ast_comb.tuple_type_pair ~loc `Run arity  in 
  let pval_type =
    arrow ~loc "" (lift_curry_type ~loc args_type result_type) fn_type in 
  Ast_comb.create_local_external loc ~pval_prim ~pval_type 
    (("", fn) :: List.map (fun x -> "",x) args )


let fn_run loc fn args 
    (mapper : Ast_mapper.mapper) 
    (e : Parsetree.expression) pexp_attributes = 
  let fn = mapper.expr mapper fn in 
  let args = 
    List.map 
      (fun (label, e) -> 
         if label <> "" then 
           Location.raise_errorf ~loc "label is not allowed here";
         mapper.expr mapper e
      ) args in 
  let len = List.length args in 
  match args with 
  | [ {pexp_desc = Pexp_construct ({txt = Lident "()"}, None)}]
    -> {e with pexp_desc = gen_fn_run loc 0 fn []}
  | _ -> 
    {e with
     pexp_desc = gen_fn_run loc len fn args; 
     pexp_attributes 
    }

let method_run loc (obj : Parsetree.expression) 
    name (args : (string * Parsetree.expression) list ) e 
    (mapper : Ast_mapper.mapper) : Parsetree.expression = 
  let obj = mapper.expr mapper obj in
  let args =
    List.map (fun (label,e) ->
        if label <> "" then
          Location.raise_errorf ~loc "label is not allowed here"        ;
        mapper.expr mapper e
      ) args in
  let len = List.length args in
  let method_kind = 
    if name = Literals.case_set then `Case_setter
    else if Ext_string.ends_with name Literals.setter_suffix then `Setter
    else `Normal name in 
  let () = 
     if method_kind = `Setter && len <> 1 then 
        Location.raise_errorf ~loc "setter expect single argument"
     else if method_kind = `Case_setter && len <> 2 then 
       Location.raise_errorf ~loc "case_set would expect arity of 2 "
  in
  match args with 
  | [ {pexp_desc = Pexp_construct ({txt = Lident "()"}, None)}]
    -> 
    {e with pexp_desc = 
              gen_fn_run loc 0
                (Exp.mk ~loc @@ down_with_name ~loc obj name)
                []
    }
  | _ -> 
    {e with pexp_desc = 
              gen_fn_run loc len 
                (Exp.mk ~loc @@ down_with_name ~loc obj name)
                args
    }



let gen_fn_mk loc arity arg  : Parsetree.expression_desc = 
  let pval_prim = [ "js_fn_mk"; string_of_int arity]  in
  let fn_type , args_type, result_type  = Ast_comb.tuple_type_pair ~loc `Make arity  in 
  let pval_type = arrow ~loc "" fn_type (lift_curry_type ~loc args_type result_type) in
  Ast_comb.create_local_external loc ~pval_prim ~pval_type [("", arg)]

let gen_method_mk loc arity arg  : Parsetree.expression_desc = 
  let pval_prim = [ "js_fn_method"; string_of_int arity]  in
  let fn_type , (obj_type, tuple_type) = Ast_comb.obj_type_pair ~loc  arity  in 
  let pval_type = 
    arrow ~loc "" fn_type (lift_js_meth_callback ~loc (obj_type, tuple_type))
  in
  Ast_comb.create_local_external loc ~pval_prim ~pval_type [("", arg)]




let empty_payload = Parsetree.PStr []

let bs_object_attribute  : Parsetree.attribute
  = {txt = "bs.obj" ; loc = Location.none}, empty_payload

let bs_uncurry_attribute : Parsetree.attribute        
  =  {txt = "fn" ; loc = Location.none}, empty_payload
let bs_meth_attribute : Parsetree.attribute        
  =  {txt = "meth_callback" ; loc = Location.none}, empty_payload



let process_attributes_rev (attrs : Parsetree.attributes) = 
  List.fold_left (fun (acc, st) attr -> 
      let tag = fst attr in
      match tag.Location.txt, st  with 
      | "fn", (`Nothing | `Uncurry) 
        -> 
        (acc, `Uncurry)
      | "meth_callback", (`Nothing | `Meth)
        -> (acc, `Meth)
      | "fn", `Meth 
      | "meth_callback", `Uncurry
        -> Location.raise_errorf 
             ~loc:tag.Location.loc 
             "[@meth_callback] and [@fn] can not be applied at the same time"
      | _ , _ -> 
        (attr::acc , st)
    ) ([], `Nothing) attrs


(** TODO: how to handle attributes *)
let destruct_arrow loc (first_arg : Parsetree.core_type) 
    (typ : Parsetree.core_type) (mapper : Ast_mapper.mapper) = 
  let rec aux acc (typ : Parsetree.core_type) = 
    (* in general, 
       we should collect [typ] in [int -> typ] before transformation, 
       however: when attributes [fn] and [meth_callback] found in typ, 
       we should stop 
    *)
    match process_attributes_rev typ.ptyp_attributes with 
    | _ , `Nothing -> 
      begin match typ.ptyp_desc with 
      | Ptyp_arrow (label, arg, body)
        -> 
        if label <> "" then
          Location.raise_errorf ~loc:typ.ptyp_loc "label is not allowed";
        aux (mapper.typ mapper arg :: acc) body 
      | _ -> mapper.typ mapper typ, acc 
      end
    | _, _ -> mapper.typ mapper typ, acc  
  in 
  let first_arg = mapper.typ mapper first_arg in
  let result, rev_extra_args = 
    aux  [first_arg] typ in 

  match rev_extra_args with 
  | [{ptyp_desc = Ptyp_constr ({txt = Lident "unit"}, [])}]
    ->
    lift_curry_type ~loc [] result 
  | _
    -> 
    lift_curry_type ~loc (List.rev rev_extra_args) result 

  
let destruct_arrow_as_meth loc (first_arg : Parsetree.core_type) 
    (typ : Parsetree.core_type) (mapper : Ast_mapper.mapper) = 
  let rec aux acc (typ : Parsetree.core_type) = 
    match process_attributes_rev typ.ptyp_attributes with 
    | _ , `Nothing -> 
      begin match typ.ptyp_desc with 
        | Ptyp_arrow (label, arg, body)
          -> 
          if label <> "" then
            Location.raise_errorf ~loc:typ.ptyp_loc "label is not allowed";
          aux (mapper.typ mapper arg :: acc) body 
        | _ -> mapper.typ mapper typ, acc 
      end 
    | _, _ -> mapper.typ mapper typ, acc  
  in 
  let first_arg = mapper.typ mapper first_arg in 
  let result, rev_extra_args = aux  [] typ in 
  lift_js_meth_callback ~loc 
    (first_arg, 
     if rev_extra_args = [] then result 
     else Typ.tuple ~loc  (List.rev_append rev_extra_args [result])
    )



let destruct_arrow_as_fn loc pat body (mapper : Ast_mapper.mapper) 
    (e : Parsetree.expression) pexp_attributes = 
  let rec aux acc (body : Parsetree.expression) = 
    match process_attributes_rev body.pexp_attributes with 
    | _ , `Nothing -> 
      begin match body.pexp_desc with 
        | Pexp_fun (label,_, arg, body)
          -> 
          if label <> "" then
            Location.raise_errorf ~loc "label is not allowed";
          aux (mapper.pat mapper arg :: acc) body 
        | _ -> mapper.expr mapper body, acc 
      end 
    | _, _ -> mapper.expr mapper body, acc  
  in 
  let first_arg = mapper.pat mapper pat in  
  let result, rev_extra_args = aux [first_arg] body in 
  match rev_extra_args with 
  | [ {ppat_desc = Ppat_construct ({txt = Lident "()"}, None)}]
    -> { e with pexp_desc =         
                  gen_fn_mk loc 0 
                    (Ast_comb.fun_no_label ~loc (Ast_literal.pat_unit ~loc () ) result);
                pexp_attributes}
  | _ -> {e with 
          pexp_desc = 
            gen_fn_mk loc (List.length rev_extra_args) 
              (List.fold_left (fun e p -> Ast_comb.fun_no_label ~loc p e )
                 result rev_extra_args );
          pexp_attributes 
         }

let destruct_arrow_as_meth_callbak loc pat body (mapper : Ast_mapper.mapper) 
    (e : Parsetree.expression) pexp_attributes = 
  let rec aux acc (body : Parsetree.expression) = 
    match process_attributes_rev body.pexp_attributes with 
    | _ , `Nothing -> 
      begin match body.pexp_desc with 
        | Pexp_fun (label,_, arg, body)
          -> 
          if label <> "" then
            Location.raise_errorf ~loc "label is not allowed";
          aux (mapper.pat mapper arg :: acc) body 
        | _ -> mapper.expr mapper body, acc 
      end 
    | _, _ -> mapper.expr mapper body, acc  
  in 
  let first_arg = mapper.pat mapper pat in  
  let result, rev_extra_args = aux [first_arg] body in 
  let len = List.length rev_extra_args - 1 in 
  {e with pexp_desc = 
            gen_method_mk loc len 
              (List.fold_left 
                 (fun e p -> Ast_comb.fun_no_label ~loc p e) result rev_extra_args );
          pexp_attributes 
  }



let from_labels ~loc (labels : Asttypes.label list) : Parsetree.core_type = 
  let arity = List.length labels in 
  let tyvars = (Ext_list.init arity (fun i ->      
      Typ.var ~loc ("a" ^ string_of_int i))) in 

  let result_type =
    lift_js_type ~loc  
    @@ Typ.object_ ~loc (List.map2 (fun x y -> x ,[], y) labels tyvars) Closed

  in 
  List.fold_right2 
    (fun label tyvar acc -> arrow ~loc label tyvar acc) labels tyvars  result_type

let handle_debugger loc payload = 
  if Ast_payload.as_empty_structure payload then
    let predef_unit_type = Ast_literal.type_unit ~loc () in
    let pval_prim = ["js_debugger"] in
    Ast_comb.create_local_external loc 
      ~pval_prim
      ~pval_type:(arrow "" predef_unit_type predef_unit_type)
      [("",  Ast_literal.val_unit ~loc ())]
  else Location.raise_errorf ~loc "bs.raw can only be applied to a string"


let handle_raw loc payload = 
  begin match Ast_payload.as_string_exp payload with 
    | None -> 
      Location.raise_errorf ~loc "bs.raw can only be applied to a string"
    | Some exp -> 
      let pval_prim = ["js_pure_expr"] in
      { exp with pexp_desc = Ast_comb.create_local_external loc 
                     ~pval_prim
                     ~pval_type:(arrow "" 
                                   (Ast_literal.type_string ~loc ()) 
                                   (Ast_literal.type_any ~loc ()) )

                     ["",exp]}
  end

let handle_raw_structure loc payload = 
  begin match Ast_payload.as_string_exp payload with 
    | Some exp 
      -> 
      let pval_prim = ["js_pure_stmt"] in 
      Ast_helper.Str.eval 
        { exp with pexp_desc =
                     Ast_comb.create_local_external loc 
                       ~pval_prim
                       ~pval_type:(arrow ""
                                     (Ast_literal.type_string ~loc ())
                                     (Ast_literal.type_any ~loc ()))
                       ["",exp]}
    | None
      -> 
      Location.raise_errorf ~loc "bs.raw can only be applied to a string"
  end
