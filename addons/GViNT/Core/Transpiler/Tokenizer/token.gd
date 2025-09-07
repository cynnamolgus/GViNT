extends Gvint.ParseNode


#region: token types constants
const IDENTIFIER = "IDENTIFIER"
const TYPE = "TYPE"
const BUILTIN_TYPE = "BUILTIN_TYPE"
const ENGINE_SINGLETON = "ENGINE_SINGLETON"
const BUILTIN_CONST = "BUILTIN_CONST"
const BUILTIN_FUNC = "BUILTIN_FUNC"

const LINEBREAK = "LINEBREAK"
const UNDERSCORE = "_"
const DOT = "."
const COMMA = ","
const COLON = ":"

const PARENTHESIS_OPEN = "("
const PARENTHESIS_CLOSE = ")"

const BRACKET_OPEN = "["
const BRACKET_CLOSE = "]"

const BRACE_OPEN = "{"
const BRACE_CLOSE = "}"

const LITERAL = "LITERAL"

const KEYWORD_TRUE = "true"
const KEYWORD_FALSE = "false"
const KEYWORD_NULL = "null"

const KEYWORD_AWAIT = "await"
const KEYWORD_NOT = "not"
const KEYWORD_OR = "or"
const KEYWORD_AND = "and"
const KEYWORD_IN = "in"
const KEYWORD_IS = "is"
const KEYWORD_AS = "as"
const KEYWORD_IF = "if"
const KEYWORD_ELSE = "else"
const KEYWORD_ELIF = "elif"

const EQUALS = "="
const PLUS_EQUALS = "+="
const MINUS_EQUALS = "-="
const STAR_EQUALS = "*="
const STAR_STAR_EQUALS = "**="
const SLASH_EQUALS = "/="
const PERCENT_EQUALS = "%="
const PIPE_EQUALS = "|="
const AMPERSAND_EQUALS = "&="
const CARET_EQUALS = "^="
const GREATER_GREATER_EQUALS = ">>="
const LESS_LESS_EQUALS = "<<="

const PLUS = "+"
const MINUS = "-"
const STAR = "*"
const STAR_STAR = "**"
const SLASH = "/"
const PERCENT = "%"

const EQUALS_EQUALS = "=="
const GREATER_EQUALS = ">="
const LESS_EQUALS = "<="
const EXCLAMATION_EQUALS = "!="
const GREATER = ">"
const LESS = "<"
const EXCLAMATION = "!"
const AMPERSAND_AMPERSAND = "&&"
const PIPE_PIPE = "||"

const GREATER_GREATER = ">>"
const LESS_LESS = "<<"
const PIPE = "|"
const AMPERSAND = "&"
const CARET = "^"
const TILDE = "~"
#endregion

var type: String
var text_content: String
var start_line: int
var start_column: int
var end_line: int
var end_column: int


static func is_binary_operator(token: Gvint.Token) -> bool:
	match token.type:
		KEYWORD_IS,\
		STAR_STAR,\
		STAR,\
		SLASH,\
		PERCENT,\
		PLUS,\
		MINUS,\
		GREATER_GREATER,\
		LESS_LESS,\
		AMPERSAND,\
		CARET,\
		PIPE,\
		EQUALS_EQUALS,\
		EXCLAMATION_EQUALS,\
		LESS,\
		GREATER,\
		LESS_EQUALS,\
		GREATER_EQUALS,\
		KEYWORD_IN,\
		KEYWORD_AND,\
		AMPERSAND_AMPERSAND,\
		KEYWORD_OR,\
		PIPE_PIPE,\
		KEYWORD_AS:
			return true
		_:
			return false


static func is_unary_operator(token: Gvint.Token) -> bool:
	match token.type:
		KEYWORD_AWAIT,\
		TILDE,\
		PLUS,\
		MINUS,\
		KEYWORD_NOT,\
		EXCLAMATION:
			return true
		_:
			return false


static func is_assignment_operator(token: Gvint.Token) -> bool:
	match token.type:
		EQUALS,\
		PLUS_EQUALS,\
		MINUS_EQUALS,\
		STAR_EQUALS,\
		SLASH_EQUALS,\
		STAR_STAR_EQUALS,\
		PERCENT_EQUALS,\
		AMPERSAND_EQUALS,\
		PIPE_EQUALS,\
		CARET_EQUALS,\
		LESS_LESS_EQUALS,\
		GREATER_GREATER_EQUALS:
			return true
		_:
			return false


static func is_beginning_of_expression(token: Gvint.Token) -> bool:
	if is_unary_operator(token):
		return true
	match token.type:
		LITERAL,\
		BUILTIN_CONST,\
		BUILTIN_FUNC,\
		IDENTIFIER,\
		ENGINE_SINGLETON,\
		TYPE,\
		BUILTIN_TYPE,\
		BRACKET_OPEN,\
		BRACE_OPEN,\
		PARENTHESIS_OPEN:
			return true
		_:
			return false



func _to_string() -> String:
	return text_content


func to_debug_string() -> String:
	match type:
		IDENTIFIER:
			return IDENTIFIER + ":" + text_content
		TYPE:
			return TYPE + ":" + text_content
		ENGINE_SINGLETON:
			return ENGINE_SINGLETON + ":" + text_content
		BUILTIN_CONST:
			return BUILTIN_CONST + ":" + text_content
		BUILTIN_FUNC:
			return BUILTIN_FUNC + ":" + text_content
		LINEBREAK:
			return LINEBREAK + text_content
		_:
			return text_content
