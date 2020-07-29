open Mlwtree

let pp_str fmt str =
  Format.fprintf fmt "%s" str

let pp_id = pp_str

let pp_str fmt str =
  Format.fprintf fmt "%s" str

let pp_id = pp_str

(* -------------------------------------------------------------------------- *)

let pp_list sep pp =
  Format.pp_print_list
    ~pp_sep:(fun fmt () -> Format.fprintf fmt "%(%)" sep)
    pp

let pp_enclose pre post pp fmt x =
  Format.fprintf fmt "%(%)%a%(%)" pre pp x post

(* -------------------------------------------------------------------------- *)

type assoc  = Left | Right | NonAssoc
type pos    = PLeft | PRight | PInfix | PNone

let e_in            =  (10,  NonAssoc) (* in  *)
let e_to            =  (10,  NonAssoc) (* to  *)
let e_arrow         =  (12,  NonAssoc) (* ->  *)
let e_match         =  (14,  Right)    (* match *)
let e_if            =  (14,  Right)    (* if  *)
let e_then          =  (14,  Right)    (* then *)
let e_else          =  (16,  Right)    (* else *)
let e_comma         =  (20,  Left)     (* ,   *)
let e_semi_colon    =  (20,  Left)     (* ;   *)
let e_colon         =  (25,  NonAssoc) (* :   *)
let e_and           =  (60,  Left)     (* and *)
let e_or            =  (70,  Left)     (* or  *)
let e_equal         =  (80,  NonAssoc) (* =   *)
let e_nequal        =  (80,  NonAssoc) (* <>  *)
let e_gt            =  (90,  Left)     (* >   *)
let e_ge            =  (90,  Left)     (* >=  *)
let e_lt            =  (90,  Left)     (* <   *)
let e_le            =  (90,  Left)     (* <=  *)
let e_plus          =  (100, Left)     (* +   *)
let e_minus         =  (100, Left)     (* -   *)
let e_mult          =  (110, Left)     (* *   *)
let e_div           =  (110, Left)     (* /   *)
let e_modulo        =  (110, Left)     (* %   *)
let e_not           =  (115, Right)    (* not *)
let e_dot           =  (120, Right)    (* .   *)
let e_app           =  (140, NonAssoc) (* f ()  *)
let e_for           =  (140, NonAssoc) (* for in .  *)

let e_default       =  (0, NonAssoc)   (* ?  *)
let e_simple        =   (200, NonAssoc)   (* ?  *)
let e_top           =  (-1,NonAssoc)

(* -------------------------------------------------------------------------- *)

let pp_if c pp_true pp_false fmt x =
  match c with
  | true  -> pp_true fmt x
  | false -> pp_false fmt x

let pp_maybe c tx pp fmt x =
  pp_if c (tx pp) pp fmt x

let pp_paren pp fmt x =
  pp_enclose "(" ")" pp fmt x

let pp_maybe_paren c pp =
  pp_maybe c pp_paren pp

let maybe_paren outer inner pos pp =
  let c =
    match (outer, inner, pos) with
    | ((o, Right), (i, Right), PLeft) when o >= i -> true
    | ((o, Right), (i, NonAssoc), _)  when o >= i -> true
    | ((o, Right), (i, Left), _)      when o >= i -> true
    | ((o, Left),  (i, Left), _)      when o >= i -> true
    | ((o, NonAssoc), (i, _), _)      when o >= i -> true
    | _ -> false
  in pp_maybe_paren c pp

let needs_paren = function
  | Tdoti _  -> false
  | Tdot _   -> false
  | Tvar _   -> false
  | Tenum _  -> false
  | Tnil _   -> false
  | Tint _   -> false
  | Tstring _ -> false
  | Tnone    -> false
  | Tletin _ -> false
  | Tif _    -> false
  | Ttry _   -> false
  | Tresult  -> false
  | _ -> true

let pp_with_paren pp fmt x =
  pp_maybe (needs_paren x) pp_paren pp fmt x

let needs_paren = function
  | Tseq _ -> true
  | _      -> false

let pp_if_with_paren pp fmt x =
  pp_maybe (needs_paren x) pp_paren pp fmt x

(* -------------------------------------------------------------------------- *)

let pp_logic fmt m =
  let mod_str =
    match m with
    | Logic         -> " function"
    | Rec           -> " rec"
    | NoMod         -> "" in
  pp_str fmt mod_str

(* -------------------------------------------------------------------------- *)

let needs_paren = function
  | Tylist _ -> true
  | _ -> false

let pp_type fmt typ =
  let rec typ_str ?(pparen = false) t =
    let str =
      match t with
      | Tyint         -> "int"
      | Tystring      -> "string"
      | Tydate        -> "date"
      | Tyaddr        -> "address"
      | Tyrole        -> "role"
      | Tytez         -> "tez"
      | Tybytes       -> "bytes"
      | Tychainid     -> "chain_id"
      | Tystorage     -> "_storage"
      | Tyunit        -> "unit"
      | Tytransfers   -> "transfers"
      | Tycoll i      -> (String.capitalize_ascii i) ^ ".collection"
      | Tyview i      -> (String.capitalize_ascii i) ^ ".view"
      | Typartition i -> (String.capitalize_ascii i) ^ ".field"
      | Tyaggregate i -> (String.capitalize_ascii i) ^ ".field"
      | Tymap i       -> "map " ^ i
      | Tyrecord i    -> i
      | Tyasset i     -> i
      | Tyenum i      -> i
      | Tyoption tt   -> "option " ^ (typ_str ~pparen:(true) tt)
      | Tyset tt      -> "L.list " ^ (typ_str ~pparen:(true) tt)
      | Tylist tt     -> "L.list " ^ (typ_str ~pparen:(true) tt)
      | Tybool        -> "bool"
      | Tyuint        -> "uint"
      | Tycontract i  -> i
      | Tyrational    -> "rational"
      | Tyduration    -> "duration"
      | Tysignature   -> "signature"
      | Tykey         -> "key"
      | Tykeyhash     -> "key_hash"
      | Tystate       -> "state"
      | Tytuple l     -> "(" ^ (String.concat ", " (List.map typ_str l)) ^ ")"
    in
    if pparen && (needs_paren t) then
      "("^str^")"
    else str
  in
  pp_str fmt (typ_str typ)

(* -------------------------------------------------------------------------- *)

let pp_exn fmt e =
  let e_str =
    match e with
    | Ekeyexist           -> "KeyExist"
    | Enotfound           -> "NotFound"
    | Einvalidcaller      -> "InvalidCaller"
    | Einvalidcondition   -> "InvalidCondition"
    | Einvalidstate       -> "InvalidState"
    | Enotransfer         -> "NoTransfer"
    | Ebreak              -> "Break"
    | Einvalid (Some msg) -> "(Invalid \""^msg^"\")"
    | Einvalid None       -> "Invalid"
  in
  pp_str fmt e_str

(* -------------------------------------------------------------------------- *)

let pp_univ_decl fmt (i,t) =
  Format.fprintf fmt "%a : %a"
    (pp_list " " pp_str) i
    pp_type t

(* -------------------------------------------------------------------------- *)

let pp_ref fmt = function
  | true -> pp_str fmt " ref"
  | false -> pp_str fmt ""

let pp_lettyp fmt = function
  | Some t -> Format.fprintf fmt " : %a" pp_typ t
  | None -> pp_str fmt ""

(* -------------------------------------------------------------------------- *)

let pp_arg fmt (id, t) =
  Format.fprintf fmt "(%a : %a)"
    pp_id id
    pp_type t

let pp_args fmt l =
  if List.length l = 0
  then pp_str fmt "()"
  else Format.fprintf fmt "%a" (pp_list " " pp_arg) l

(* -------------------------------------------------------------------------- *)

let rec pp_pattern fmt = function
  | Twild -> pp_str fmt " _"
  | Tpignore -> pp_str fmt "Some _"
  | Tconst a -> pp_id fmt a
  | Tpatt_tuple l -> Format.fprintf fmt "(%a)" (pp_list "),(" (pp_pattern)) l
  | Tpsome a -> Format.fprintf fmt "Some %a" pp_id a

(* -------------------------------------------------------------------------- *)

let rec pp_term outer pos fmt = function
  | Tseq l         -> Format.fprintf fmt "@[%a@]" (pp_list ";@\n" (pp_term outer pos)) l
  | Tif (i,t, None)    ->
    Format.fprintf fmt "@[if %a@ then %a@]"
      (pp_term e_if PRight) i
      (pp_if_with_paren (pp_term e_then PRight)) t
  | Tif (i,t, Some e)    ->
    Format.fprintf fmt "@[if %a then @\n  @[%a @]@\nelse @\n  @[%a @]@]"
      (pp_term e_if PRight) i
      (pp_if_with_paren (pp_term e_then PRight)) t
      (pp_if_with_paren (pp_term e_else PRight)) e
  | Traise e -> Format.fprintf fmt "raise %a" pp_exn e
  | Tmem (t,e1,e2) ->
    Format.fprintf fmt "%a.mem %a %a"
      pp_str (String.capitalize_ascii t)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tvmem (t,e1,e2) ->
    Format.fprintf fmt "%a.vmem %a %a"
      pp_str (String.capitalize_ascii t)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tvcontains (t,e1,e2) ->
    Format.fprintf fmt "%a.contains %a %a"
      pp_str (String.capitalize_ascii t)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tccontains (t,e1,e2) ->
    Format.fprintf fmt "%a.ccontains %a %a"
      pp_str (String.capitalize_ascii t)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tlmem (i,e1,e2) ->
    Format.fprintf fmt "%a.mem %a %a"
      pp_str i
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Ttuple l ->
    Format.fprintf fmt "(%a)" (pp_list " , " (pp_term outer pos)) l
  | Ttupleaccess (e1,e2,e3) ->
    Format.fprintf fmt "nth%a_of_%a %a"
      pp_str (string_of_int e2)
      pp_str (string_of_int e3)
      (pp_with_paren (pp_term outer pos)) e1
  | Tvar i -> pp_str fmt i
  | Tdoti (i1,i2) -> Format.fprintf fmt "%a.%a" pp_str i1 pp_str i2
  | Tdot (e1,e2) ->
    Format.fprintf fmt "%a.%a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_term outer pos) e2
  | Tassign (e1,e2) ->
    Format.fprintf fmt "%a <- %a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_term outer pos) e2
  | Tadd (i,e1,e2) ->
    Format.fprintf fmt "%a.add %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tvadd (i,e1,e2) ->
    Format.fprintf fmt "%a.vadd %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tset (i,e1,e2,e3) ->
    Format.fprintf fmt "%a.set %a %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
      (pp_with_paren (pp_term outer pos)) e3
  | Tvsum (i,e1,e2) ->
    Format.fprintf fmt "%a.sum %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tcsum (i,e1) ->
    Format.fprintf fmt "%a.csum %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
  | Tcsort (i,e1) ->
    Format.fprintf fmt "%a.csort %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
  | Tvsort (i,e1,e2) ->
    Format.fprintf fmt "%a.sort %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tnth (i,e1,e2) ->
    Format.fprintf fmt "%a.nth %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tcoll (i,e) ->
    Format.fprintf fmt "%a.to_coll %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Teq (Tycoll a, e1, e2) ->
    Format.fprintf fmt "%a.(==) %a %a"
      pp_str (String.capitalize_ascii a)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
   | Teqfield (i, e1, e2) ->
    Format.fprintf fmt "%a.eq %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Teq (Tybool, e1, e2) ->
    Format.fprintf fmt "%a && %a" (pp_term outer pos) e1 (pp_term outer pos) e2
  | Teq (Tystring, e1, e2) ->
    Format.fprintf fmt "str_eq %a %a" (pp_term outer pos) e1 (pp_term outer pos) e2
  | Teq (_, e1, e2) ->
    Format.fprintf fmt "%a = %a" (pp_term outer pos) e1 (pp_term outer pos) e2
  | Tneq (Tybool, e1, e2) ->
    Format.fprintf fmt "not (%a && %a)" (pp_term outer pos) e1 (pp_term outer pos) e2
  | Tneq (Tystring, e1, e2) ->
    Format.fprintf fmt "not (str_eq %a %a)" (pp_term outer pos) e1 (pp_term outer pos) e2
  | Tneq (_, e1, e2) ->
    Format.fprintf fmt "%a <> %a" (pp_term outer pos) e1 (pp_term outer pos) e2
  | Tunion (i, e1, e2) ->
    Format.fprintf fmt "%a.union %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tinter (i,e1, e2) ->
    Format.fprintf fmt "%a.inter %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tdiff (i,e1, e2) ->
    Format.fprintf fmt "%a.diff %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Told e ->
    Format.fprintf fmt "old %a"
      (pp_with_paren (pp_term outer pos)) e
  | Tsingl (i,e) ->
    Format.fprintf fmt "%a.singleton %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Tempty (i,e) ->
    Format.fprintf fmt "%a.is_empty %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Tvempty (i,e) ->
    Format.fprintf fmt "%a.is_empty %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Tint i -> pp_str fmt (Big_int.string_of_big_int i)
  | Tstring s -> Format.fprintf fmt "\"%a\"" pp_str s
  | Tforall (ud,b) ->
    Format.fprintf fmt "@[forall %a.@\n%a@]"
      (pp_list ", " pp_univ_decl) ud
      (pp_term e_default PRight) b
  | Texists (ud,b) ->
    Format.fprintf fmt "@[exists %a.@\n%a@]"
      (pp_list ", " pp_univ_decl) ud
      (pp_term e_default PRight) b
  | Timpl (e1,e2) ->
    Format.fprintf fmt "@[%a ->@\n%a @]"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tequiv (e1,e2) ->
    Format.fprintf fmt "@[%a <->@\n%a @]"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tand (e1,e2) ->
    Format.fprintf fmt "%a /\\ %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tfalse -> Format.fprintf fmt "false"
  | Ttrue -> Format.fprintf fmt "true"
  | Tor (e1,e2) ->
    Format.fprintf fmt "%a || %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tgt (Tystring,e1,e2) ->
    Format.fprintf fmt "str_gt %a %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tgt (_,e1,e2) ->
    Format.fprintf fmt "%a > %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tge (Tystring,e1,e2) ->
    Format.fprintf fmt "str_ge %a %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tge (_,e1,e2) ->
    Format.fprintf fmt "%a >= %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tlt (Tystring,e1,e2) ->
    Format.fprintf fmt "str_lt %a %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tlt (_,e1,e2) ->
    Format.fprintf fmt "%a < %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tle (Tystring,e1,e2) ->
    Format.fprintf fmt "str_le %a %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tle (_,e1,e2) ->
    Format.fprintf fmt "%a <= %a"
      (pp_term e_default PRight) e1
      (pp_term e_default PRight) e2
  | Tapp (f,[]) ->
    Format.fprintf fmt "%a ()"
      (pp_with_paren (pp_term outer pos)) f
  | Tapp (f,a) ->
    Format.fprintf fmt "%a %a"
      (pp_with_paren (pp_term outer pos)) f
      (pp_list " " (pp_with_paren (pp_term outer pos))) a
  | Tget (i,e1,e2) ->
    Format.fprintf fmt "%a.get %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tgetforce (i,e1,e2) ->
    Format.fprintf fmt "%a.get_force %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tfget (i,e1,e2) ->
    Format.fprintf fmt "%a.fget %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Trecord (None,l) ->
    Format.fprintf fmt "{@\n  @[%a@]@\n}"
      (pp_list ";@\n" pp_recfield) l
  | Trecord (Some e,l) ->
    Format.fprintf fmt "{ %a with@\n  @[%a@]@\n}"
      (pp_with_paren (pp_term outer pos)) e
      (pp_list ";@\n" pp_recfield) l
  | Tnone -> pp_str fmt "None"
  | Tenum i -> pp_str fmt i
  | Tmark (i,e) -> Format.fprintf fmt "label %a in %a"
    pp_str (String.capitalize_ascii i)
    (pp_with_paren (pp_term outer pos)) e
  | Tat (i,e) -> Format.fprintf fmt "(%a at %a)"
    (pp_with_paren (pp_term outer pos)) e
    pp_str (String.capitalize_ascii i)
  | Tunit -> pp_str fmt "()"
  | Tsome e -> Format.fprintf fmt "Some %a" (pp_with_paren (pp_term e_default PRight)) e
  | Tnot e -> Format.fprintf fmt "not %a" (pp_with_paren (pp_term outer pos)) e
  | Tpand (e1,e2) -> Format.fprintf fmt "(%a && %a)"
                       (pp_with_paren (pp_term outer pos)) e1
                       (pp_with_paren (pp_term outer pos)) e2
  | Tlist l -> pp_tlist outer pos fmt l
  | Tnil i -> Format.fprintf fmt "%a.Nil" pp_str i
  | Temptycoll i -> Format.fprintf fmt "%a.empty" pp_str (String.capitalize_ascii i)
  | Temptyview i -> Format.fprintf fmt "%a.empty" pp_str i
  | Temptyfield i -> Format.fprintf fmt "%a.empty" pp_str i
  | Tcaller i -> Format.fprintf fmt "%a._caller" pp_str i
  | Tsender i -> Format.fprintf fmt "%a._source" pp_str i
  | Ttransferred i -> Format.fprintf fmt "%a._transferred" pp_str i
  | Tfst e -> Format.fprintf fmt "fst %a" (pp_with_paren (pp_term outer pos)) e
  | Tsnd e -> Format.fprintf fmt "snd %a" (pp_with_paren (pp_term outer pos)) e
  | Tabs e -> Format.fprintf fmt "abs %a" (pp_with_paren (pp_term outer pos)) e
  | Tletin (r,i,t,b,e) ->
    Format.fprintf fmt "let%a %a%a = %a in@\n%a"
      pp_ref r
      pp_str i
      pp_lettyp t
      (pp_term outer pos) b
      (pp_if_with_paren (pp_term outer pos)) e
  | Tletfun (s,e) ->
    Format.fprintf fmt "@[%a@] in@\n%a"
      pp_fun s
      (pp_term outer pos) e
  | Tfor (i,f,s,l,b) ->
    Format.fprintf fmt "for %a = %a to %a do@\n@[%a@]@\n  @[%a@]@\ndone"
      pp_str i
      (pp_term outer pos) f
      (pp_term outer pos) s
      (pp_invariants false) l
      (pp_term outer pos) b
  | Ttry (b,l) ->
    Format.fprintf fmt "try@\n  @[%a@]@\nwith @\n@[%a@]@\nend"
      (pp_term outer pos) b
      (pp_list "@\n" pp_catch) l
  | Tassert (None,e) ->
    Format.fprintf fmt "assert { %a }"
      (pp_term outer pos) e
  | Tassert (Some lbl,e) ->
    Format.fprintf fmt "assert { [@expl:%a] %a }"
      pp_str lbl
      (pp_term outer pos) e
  | Tcard (i,e) ->
    Format.fprintf fmt "%a.card %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e

  | Tmkcoll (i,l) ->
    Format.fprintf fmt "%a.from_list (%a)"
      pp_str (String.capitalize_ascii i)
      (pp_tlist outer pos) l
  | Tmkview (i,e) ->
    Format.fprintf fmt "%a.mk %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Tcontent (i,e) ->
    Format.fprintf fmt "%a.elts %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Tcontains (i,e1,e2) ->
    Format.fprintf fmt "%a.contains %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tvcontent (i,e) ->
    Format.fprintf fmt "%a.vcontent %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Ttocoll (i,e1,e2) ->
    Format.fprintf fmt "%a.to_coll %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Ttoview (i,e) ->
    Format.fprintf fmt "%a.to_view %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Tviewtolist (i,e1,e2) ->
    Format.fprintf fmt "%a.view_to_list %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Telts (i,e) ->
    Format.fprintf fmt "%a.elts %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e
  | Tshallow (i,e1,e2) ->
    Format.fprintf fmt "%a.shallow %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tplus (_,e1,e2) ->
    Format.fprintf fmt "%a + %a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tminus (_,e1,e2) ->
    Format.fprintf fmt "%a - %a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tmult (_,e1,e2) ->
    Format.fprintf fmt "%a * %a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tdiv (_,e1,e2) ->
    Format.fprintf fmt "div %a %a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tmod (_,e1,e2) ->
    Format.fprintf fmt "mod %a %a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tcnth (i,e1,e2) ->
    Format.fprintf fmt "%a.cnth %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tvnth (i,e1,e2) ->
    Format.fprintf fmt "%a.vnth %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tlnth _ -> pp_str fmt "TODO_Tlnth"
  | Twitness i ->
    Format.fprintf fmt "%a.witness"
      pp_str (String.capitalize_ascii i)
  | Tdle (_,e1,e2,e3) ->
    Format.fprintf fmt "%a <= %a <= %a"
      (pp_term outer pos) e1
      (pp_term outer pos) e2
      (pp_term outer pos) e3
  | Tresult -> pp_str fmt "result"
  | Tsubset (i,e1,e2) ->
    Format.fprintf fmt "%a.subset %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tctail (i,e1,e2) ->
    Format.fprintf fmt "%a.tail %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tvtail (i,e1,e2) ->
    Format.fprintf fmt "%a.tail %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tnow i -> Format.fprintf fmt "%a._now" pp_str i
  | Tchainid i -> Format.fprintf fmt "%a._chainid" pp_str i
  | Tmlist (l,e1,i1,i2,i3,e2) ->
    Format.fprintf fmt "@[match %a with@\n| %a.Nil -> %a@\n| %a.Cons %a %a -> @\n  @[%a@]@\nend@]"
      pp_str i1
      pp_str l
      (pp_term outer pos) e1
      pp_str l
      pp_str i2
      pp_str i3
      (pp_term outer pos) e2
  | Tmatch (t,l) ->
    Format.fprintf fmt "@[match %a with@\n| %a @\nend@]"
      (pp_term outer pos) t
      (pp_list "@\n|" pp_case) l
  | Tcons (i,e1,e2) ->
    Format.fprintf fmt "%a.Cons %a %a"
      pp_str i
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tremove (i,e1,e2) ->
    Format.fprintf fmt "%a.remove %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tvremove (i,e1,e2) ->
    Format.fprintf fmt "%a.remove %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Texn e -> Format.fprintf fmt "%a" pp_exn e
  | Tnottranslated -> pp_str fmt "NOT TRANSLATED"
  | Tename -> pp_str fmt "TODO_Tename"
  | Ttobereplaced -> pp_str fmt "TODO_Ttobereplaced"
  | Tadded _ -> pp_str fmt "TODO_Tadded"
  | Trmed _ -> pp_str fmt "TODO_Trmed"
  | Tconcat (_, _) -> pp_str fmt "TODO_Tconcat"
  | Ttransfer (e1,e2) ->
    Format.fprintf fmt "transfer %a %a"
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tcall e ->
    Format.fprintf fmt "call %a"
      (pp_with_paren (pp_term outer pos)) e
  | Tmktr (_, _) -> pp_str fmt "TODO_Tmktr"
  | Ttradd _ -> pp_str fmt "TODO_Ttradd"
  | Ttrrm _ -> pp_str fmt "TODO_Ttrrm"
  | Tuminus (_, v) -> Format.fprintf fmt "- %a" (pp_with_paren (pp_term outer pos)) v
  | Tdlt (_, _, _, _) -> pp_str fmt "TODO_Tdlt"
  | Tdlet (_, _, _, _) -> pp_str fmt "TODO_Tdlet"
  | Tdlte (_, _, _, _) -> pp_str fmt "TODO_Tdlte"
  | Taddr _ -> pp_str fmt "TODO_Taddr"
  | Tbytes _ -> pp_str fmt "TODO_Tbytes"
  | Tvhead (i,e1,e2) ->
    Format.fprintf fmt "%a.head %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
  | Tchead (i,e1,e2) ->
    Format.fprintf fmt "%a.head %a %a"
      pp_str (String.capitalize_ascii i)
      (pp_with_paren (pp_term outer pos)) e1
      (pp_with_paren (pp_term outer pos)) e2
and pp_recfield fmt (n,t) =
  Format.fprintf fmt "%a = %a"
    pp_str n
    (pp_term e_default PRight) t
and pp_tlist outer pos fmt = function
  | []    -> pp_str fmt "L.Nil"
  | e::tl -> Format.fprintf fmt "L.Cons %a (%a)"
               (pp_with_paren (pp_term outer pos)) e
               (pp_tlist outer pos) tl
and pp_formula fmt f =
  Format.fprintf fmt "@[ [@expl:%a]@\n %a @]"
    pp_str f.id
    (pp_term e_default PRight) f.form
and pp_invariants nl fmt invs =
  if List.length invs = 0
  then pp_str fmt ""
  else
    (if nl then pp_str fmt "\n";
     Format.fprintf fmt "invariant {@\n %a @\n} "
       (pp_list "@\n}@\ninvariant {@\n " pp_formula) invs)
and pp_ensures fmt ensures =
  if List.length ensures = 0
  then pp_str fmt ""
  else
    Format.fprintf fmt "ensures {@\n %a @\n}@\n"
      (pp_list "@\n}@\nensures {@\n " pp_formula) ensures
and pp_requires fmt requires =
  if List.length requires = 0
  then pp_str fmt ""
  else
    Format.fprintf fmt "requires {@\n %a @\n}@\n"
      (pp_list "@\n}@\nrequires {@\n" pp_formula) requires
and pp_variants fmt variants =
  if List.length variants = 0
  then pp_str fmt ""
  else
    Format.fprintf fmt "variant { %a }@\n"
      (pp_list ", " (pp_term e_default PRight)) variants
and pp_fun fmt (s : fun_struct) =
  Format.fprintf fmt "let%a %a %a : %a@\n%a%a%a%a=  @[%a@]"
    pp_logic s.logic
    pp_id s.name
    pp_args s.args
    pp_type s.returns
    pp_variants s.variants
    (pp_raise e_top PRight) s.raises
    pp_requires s.requires
    pp_ensures s.ensures
    (pp_term e_top PRight) s.body
and pp_raise outer pos fmt raises =
  if List.length raises = 0
  then pp_str fmt ""
  else
    Format.fprintf fmt "@[raises { %a }@\n@]"
      (pp_list " }@\nraises { " (pp_term outer pos)) raises
and pp_catch fmt (exn,e) =
  Format.fprintf fmt "| %a -> %a"
    pp_exn exn
    (pp_term e_top PRight) e
and pp_case fmt (p,t) =
  Format.fprintf fmt "%a -> %a"
    pp_pattern p
    (pp_term e_top PRight) t

(* -------------------------------------------------------------------------- *)

let pp_mutable fmt m =
  let m_str = if m then "mutable " else "" in
  pp_str fmt m_str

let pp_field fmt (f : field) =
  Format.fprintf fmt "%a%a : %a"
    pp_mutable f.mutable_
    pp_str f.name
    pp_type f.typ

(* -------------------------------------------------------------------------- *)

let pp_record fmt (i,fl) =
  Format.fprintf fmt "type %a = {@\n  @[%a@] @\n}"
    pp_str i
    (pp_list ";@\n" pp_field) fl

(* -------------------------------------------------------------------------- *)

let pp_init fmt (f : field) =
  Format.fprintf fmt "%a = %a"
    pp_str f.name
    (pp_term e_default PRight) f.init

let pp_storage fmt (s : storage_struct) =
  Format.fprintf fmt "type _storage = {@\n  @[%a @]@\n} %aby {@\n  @[%a @]@\n}"
    (pp_list ";@\n" pp_field) s.fields
    (pp_invariants false) s.invariants
    (pp_list ";@\n" pp_init) s.fields

(* -------------------------------------------------------------------------- *)

let pp_enum fmt (i,l) =
  Format.fprintf fmt "type %a =%a"
    pp_str i
    (fun fmt x -> match l with
       | [] -> Format.fprintf fmt " Unit"
       | _ -> Format.fprintf fmt "@\n @[| %a@]" (pp_list "@\n| " pp_str) x) l

(* -------------------------------------------------------------------------- *)

let pp_qualid fmt q = Format.fprintf fmt "%a" (pp_list "." pp_str) q

(* -------------------------------------------------------------------------- *)

let pp_clone_subst fmt = function
  | Ctype (i,t) -> Format.fprintf fmt "type %a = %a" pp_str i pp_type t
  | Cval (i,j)  -> Format.fprintf fmt "val %a = %a" pp_str i pp_str j
  | Cfun (i,j)  -> Format.fprintf fmt "function %a = %a" pp_str i pp_str j
  | Cpred (i,j)  -> Format.fprintf fmt "predicate %a = %a" pp_str i pp_str j

let pp_clone fmt (i,j,l) =
  Format.fprintf fmt "clone %a as %a with @[%a@]"
    pp_qualid i
    pp_str j
    (pp_list ",@\n" pp_clone_subst) l

(* -------------------------------------------------------------------------- *)

let pp_theotyp fmt = function
  | Theo  -> pp_str fmt "theorem"
  | Axiom -> pp_str fmt "axiom"
  | Lemma -> pp_str fmt "lemma"
  | Goal  -> pp_str fmt "goal"

let pp_theorem fmt (t,i,e) =
  Format.fprintf fmt "%a %a:@\n  @[%a@]"
    pp_theotyp t
    pp_str i
    (pp_term e_default PRight) e

(* -------------------------------------------------------------------------- *)

let pp_val fmt (i,t) =
  Format.fprintf fmt "val %a : %a"
    pp_str i
    pp_type t

(* -------------------------------------------------------------------------- *)

let pp_decl fmt = function
  | Duse (true, l, None)    -> Format.fprintf fmt "use export %a" pp_qualid l
  | Duse (true, l, Some _)  -> Format.fprintf fmt "use export %a" pp_qualid l
  | Duse (false, l, None)   -> Format.fprintf fmt "use %a" pp_qualid l
  | Duse (false, l, Some a) -> Format.fprintf fmt "use %a as %a" pp_qualid l pp_str a
  | Dval (i,t)       -> pp_val fmt (i,t)
  | Dclone (i,j,l)   -> pp_clone fmt (i,j,l)
  | Denum (i,l)      -> pp_enum fmt (i,l)
  | Drecord (i,l)    -> pp_record fmt (i,l)
  | Dstorage s       -> pp_storage fmt s
  | Dtheorem (t,i,e) -> pp_theorem fmt (t,i,e)
  | Dfun s           -> pp_fun fmt s

let pp_module fmt (m : mlw_module) =
  Format.fprintf fmt "module %a@\n  @[%a@]@\nend"
    pp_str m.name
    (pp_list "@\n@\n" pp_decl) m.decls

let pp_mlw_tree fmt (tree : mlw_tree) =
  Format.fprintf fmt "%a"
    (pp_list "@\n" pp_module) tree

(* -------------------------------------------------------------------------- *)
let string_of__of_pp pp x =
  Format.asprintf "%a" pp x

let show_mlw_tree x = string_of__of_pp pp_mlw_tree x
