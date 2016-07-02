[@@@bs.config{bs_class_type = true }]

class type widget = 
  object 
      method on : string ->  (event -> unit [@fn]) -> unit 
  end
and  event = 
  object 
    method source : widget
    method target : widget
  end


class type title = 
  object 
    method title_set : string -> unit 
    method title : string
  end

class type text = 
    object
      method text_set : string -> unit 
      method text : string 
    end
class type measure =
    object
      method minHeight_set : int -> unit 
      method minHeight : int
      method minWidth_set : int -> unit 
      method minWidth : int 
      method maxHeight_set : int -> unit 
      method maxHeight : int 
      method maxWidth_set : int -> unit 
      method maxWidth : int 
    end

class type layout = 
    object 
      method orientation_set : string -> unit  
      method orientation : string
    end

class type applicationContext = 
  object 
    method exit : int -> unit 
  end
class type contentable = 
  object
    method content_set : #widget Js.t -> unit 
    method content : #widget Js.t 
    method contentWidth : int  
    method contentWidth_set : int -> unit 
  end

class type hostedWindow =
  object
    inherit widget 
    inherit title
    inherit contentable
    method show : unit -> unit 
    method hide : unit -> unit 
    method focus : unit -> unit 
    method appContext_set : applicationContext -> unit
  end

class type hostedContent =
  object 
    inherit widget
    inherit contentable
  end


class type stackPanel = 
  object
    inherit measure
    inherit layout 
    inherit widget

    method addChild : #widget Js.t -> unit 

  end

class type grid  = 
  object
    inherit widget
    inherit measure
    method columns_set : [%bs.obj: <width : int; .. >  ]  array -> unit 
    method titleRows_set : 
      [%bs.obj: <label : <text : string; .. >   ; ..> ]   array -> unit 
    method dataSource_set :
      [%bs.obj: <label : <text : string; .. >   ; ..>  ]  array array -> unit  
  end


class type button = 
  object
    inherit widget
    inherit text
    inherit measure
  end

class type textArea = 
  object
    inherit widget
    inherit measure
    inherit text 
  end


external set_interval : (unit -> unit [@fn]) -> float -> unit  =  "setInterval"
    [@@bs.call] [@@bs.module "@runtime" "Runtime"]

external to_fixed : float -> int -> string = "toFixed" [@@bs.send ]
