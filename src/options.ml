type target_lang =
  | Markdown
  | Michelson
  | MichelsonStorage
  | Whyml
  | Javascript
[@@deriving show {with_path = false}]

type storage_policy =
  | Record
  | Flat
  | Hybrid of (string * string) list
[@@deriving show {with_path = false}]

type execution_mode =
  | WithSideEffect
  | WithoutSideEffect
[@@deriving show {with_path = false}]

type sorting_policy =
  | OnTheFly
  | OnChange
  | None
[@@deriving show {with_path = false}]

let version = "1.2.6"
let url = "https://archetype-lang.org/"

let target = ref (Michelson : target_lang)

let storage_policy = ref Record
let execution_mode = ref WithSideEffect
let sorting_policy = ref OnTheFly

let with_init_caller = ref true

let opt_lsp     = ref false
let opt_service = ref false
let opt_json    = ref false
let opt_rjson   = ref false
let opt_pt      = ref false
let opt_extpt   = ref false
let opt_ext     = ref false
let opt_ast     = ref false
let opt_mdl     = ref false
let opt_omdl    = ref false
let opt_typed   = ref false
let opt_ir      = ref false
let opt_dir     = ref false
let opt_red_dir = ref false
let opt_mic     = ref false
let opt_mici    = ref false
let opt_all_parenthesis = ref false
let opt_m     = ref false
let opt_raw   = ref false
let opt_raw_whytree = ref false
let opt_raw_ir = ref false
let opt_raw_michelson = ref false
let opt_caller = ref "$CALLER_ADDRESS"
let opt_decomp = ref false
let opt_trace = ref false
let opt_metadata_uri = ref ""
let opt_metadata_storage = ref ""
let opt_with_metadata = ref false
let opt_expr : (string option) ref = ref (None : string option)
let opt_entrypoint : (string option) ref = ref (None : string option)
let opt_type : (string option) ref = ref (None : string option)
let opt_show_entries = ref false
let opt_with_contract = ref false
let opt_code_only = ref false
let opt_expr_only = ref false
let opt_init = ref ""
let opt_no_js_header = ref false
let opt_to_micheline = ref (None : string option)
let opt_why3session = ref (None : string option)
let opt_sdir = ref false
let opt_get_parameters = ref false
let opt_test_mode = ref false

let opt_property_focused = ref ""

let opt_vids : (string list) ref = ref []
let add_vids s =
  opt_vids := s::!opt_vids
