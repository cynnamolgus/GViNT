extends RefCounted


#region: token types constants
const IDENTIFIER = "IDENTIFIER"
const TYPE = "TYPE"
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


func _to_string() -> String:
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
