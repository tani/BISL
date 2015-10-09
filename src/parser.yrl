Nonterminals list elements element exp.
Terminals integer float string symbol char '(' ')' '\'' ',' ',@' '`' '#\''.
Rootsymbol exp.

exp -> list    : '$1'.
exp -> string  : extract_token('$1').
exp -> symbol  : extract_token('$1').
exp -> integer : extract_token('$1').
exp -> float   : extract_token('$1').
exp -> char    : extract_token('$1').
exp -> '\'' exp : ['_QUOTE',    '$2'].
exp -> ',@' exp : ['_SPLICE',  '$2'].
exp -> ','  exp : ['_UNQUOTE',   '$2'].
exp -> '`'  exp : ['_BACKQUOTE','$2'].
exp -> '#\''  exp : ['_FUNCTION','$2'].

list -> '('')'         : [].
list -> '('elements')' : '$2'.
list -> '('element')'  : ['$2'].
element -> exp    : '$1'.
elements -> element elements  : ['$1'|'$2'].
elements -> element    : ['$1'].

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
