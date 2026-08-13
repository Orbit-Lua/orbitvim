; extends

; These nodes are recognized by tree-sitter-sql but are not captured by its
; upstream highlights query. ENABLE and DISABLE are used by SQL Server index
; and trigger statements.
[
  (keyword_enable)
  (keyword_disable)
] @keyword

; SQL Server TOP is currently parsed as a function invocation. Correct the
; semantic capture without treating every identifier named "top" as a keyword.
((invocation
  (object_reference
    name: (identifier) @keyword))
  (#vim-match? @keyword "\\c^top$")
  (#set! priority 110))

; SET options remain object references inside an error-recovery node. Keep the
; correction limited to the options OrbitVim's T-SQL conventions generate.
((ERROR
  (keyword_set)
  (object_reference
    name: (identifier) @keyword))
  (#vim-match? @keyword "\\c^nocount$")
  (#set! priority 110))

((ERROR
  (keyword_set)
  (object_reference
    name: (identifier) @keyword))
  (#vim-match? @keyword "\\c^xact_abort$")
  (#set! priority 110))
