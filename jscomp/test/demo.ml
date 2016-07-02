open Demo_binding
external addChild : stackPanel -> #widget -> unit = "x" [@@bs.send]


external new_HostedWindow : unit -> hostedWindow Js.t = "HostedWindow"
    [@@bs.new ] [@@bs.module "@blp/ui" "BUI"]

external new_HostedContent : unit -> hostedContent Js.t = "" 
    [@@bs.new "HostedContent"] [@@bs.module "@blp/ui" "BUI"]

external new_StackPanel : unit -> stackPanel Js.t = "" 
    [@@bs.new "StackPanel"] [@@bs.module "@ui" "UI"]

external new_textArea : unit -> textArea Js.t = "" 
    [@@bs.new "TextArea"] [@@bs.module "@ui" "UI"]

external new_button : unit -> button Js.t = ""
    [@@bs.new "Button"] [@@bs.module "@ui" "UI"]

external new_grid : unit -> grid Js.t = ""
    [@@bs.new "Grid"] [@@bs.module "@ui" "UI"]

(* Note, strictly speaking, it 's not returning a primitive string, it returns
   an object string *)
external stringify : 'a -> string = ""
    [@@bs.new "String"] 

external random : unit -> float = ""
    [@@bs.call "Math.random"] 

external array_map : 'a array -> ('a -> 'b [@fn]) -> 'b array = ""
    [@@bs.call"Array.prototype.map.call"] 

type env 
external mk_bid_ask : bid:float -> ask:float -> env = "" [@@bs.obj]  


type data = { ticker : string ; price : float }


let data = 
[|
  { ticker = "GOOG" ; price = 700.0; };
  { ticker = "AAPL" ; price = 500.0; };
  { ticker = "MSFT" ; price = 300.0; }
|];;


let ui_layout 
    (compile  : string -> (string -> float) -> float) lookup  appContext
  : hostedWindow Js.t = 
  let init = compile "bid  - ask" in
  let computeFunction = ref (fun env -> init (fun key -> lookup env key) ) in
  let hw1 = new_HostedWindow ()  in
  let hc = new_HostedContent () in
  let stackPanel = new_StackPanel () in
  let inputCode = new_textArea () in

  let button = new_button () in
  let grid = new_grid () in
  begin 
    hw1##appContext_set appContext;
    hw1##title_set "Test Application From OCaml";
    hw1##content_set hc;


    hc##contentWidth_set 700;
    hc##content_set stackPanel;

    stackPanel##orientation_set "vertical";
    stackPanel##minHeight_set 10000; (* FIXME -> 1e4 *)
    stackPanel##minWidth_set 4000;

    stackPanel##addChild grid;
    stackPanel##addChild inputCode;
    stackPanel##addChild button;
    let mk_titleRow text = [%bs.obj {label =  {text }  } ] in
    let u =  [%bs.obj {width =  200} ]  in
    grid##minHeight_set 300;
    grid##titleRows_set
        [| mk_titleRow "Ticker";
           mk_titleRow "Bid";
           mk_titleRow "Ask";
           mk_titleRow "Result" |] ;
    grid##columns_set [| u;u;u;u |];

    inputCode##text_set " bid - ask";
    inputCode##minHeight_set 100;

    button##text_set "update formula";
    button##minHeight_set 20;
    button##on "click" begin fun [@fn] _event -> (* FIXME both [_] and () should work*)
      try 
        let hot_function = compile inputCode##text in
        computeFunction := fun env ->  hot_function (fun key -> lookup env key) 
      with  e -> ()
    end;
    let fmt v = to_fixed v 2 in
    set_interval (fun [@fn] () -> 

      grid##dataSource_set
        ( array_map data (fun [@fn] {ticker; price } -> 
          let bid = price +. 20. *. random () in
          let ask = price +. 20. *. random () in
          let result = !computeFunction (mk_bid_ask ~bid ~ask ) in
          [| mk_titleRow ticker;
             mk_titleRow (fmt bid);
             mk_titleRow (fmt ask);
             mk_titleRow (fmt result)
           |]))) 100. ; 
    hw1
  end

