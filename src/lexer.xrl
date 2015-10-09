Definitions.

FLOAT      = [0-9]*\.[0-9]+
INTEGER    = [0-9]+
CHARACTER  = #\\.
SYMBOL     = [A-Za-z0-9+\-<>/*&=.?_!$%:@[\]^{}]+
WHITESPACE = [\s\t\n\r]+
STRING     = "(\\"|[^"])*"
COMMENT    = ;.*\n

Rules.
{FLOAT}       : {token, {float,   TokenLine, list_to_float(TokenChars)}}.
{INTEGER}     : {token, {integer, TokenLine, list_to_integer(TokenChars)}}.
{CHARACTER}   : {token, {char,    TokenLine, list_to_char(TokenChars)}}.
{SYMBOL}      : {token, {symbol,  TokenLine, list_to_symbol(TokenChars)}}.
{STRING}      : {token, {string,  TokenLine, list_to_law_string(TokenChars)}}.

{WHITESPACE}  : skip_token.
{COMMENT}     : skip_token.

\(            : {token, {'(', TokenLine}}.
\)            : {token, {')', TokenLine}}.
'       : {token, {'\'', TokenLine}}.
`       : {token, {'`',  TokenLine}}.
,@      : {token, {',@', TokenLine}}.
,       : {token, {',',  TokenLine}}.
#'      : {token, {'#\'',TokenLine}}.

Erlang code.
list_to_symbol(Chars) ->
  list_to_atom(string:to_upper(Chars)).
list_to_law_string(Chars) ->
  list_to_binary(tl(lists:droplast(Chars))).
list_to_char(Chars) ->
  lists:last(Chars).