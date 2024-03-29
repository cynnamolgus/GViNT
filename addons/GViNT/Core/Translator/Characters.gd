extends Reference



const SPACE = " "
const TAB = "	"
const LINEBREAK = "\n"
const BACKSLASH = "\\"

const COMMENT_MARK = "#"
const MULTILINE_COMMENT_MARK = "###"

const UNDERSCORE = "_"
const COLON = ":"
const DOT = "."
const COMMA = ","
const QUOTE = "\""


const OPEN_BRACE = "{"
const CLOSE_BRACE = "}"

const OPEN_BRACKET = "["
const CLOSE_BRACKET = "]"

const OPEN_PARENTHESIS = "("
const CLOSE_PARENTHESIS = ")"

const WRAPPING_CHARS = (
	OPEN_BRACE + CLOSE_BRACE
	+ OPEN_BRACKET + CLOSE_BRACKET
	+ OPEN_PARENTHESIS + CLOSE_PARENTHESIS
)


const DIGITS = "0123456789"
const LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
const UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const LETTERS = LOWERCASE + UPPERCASE
const ALPHANUMERIC = LETTERS + DIGITS
const HEX = "abcdefABCDEF" + DIGITS
const BINARY = "01"

const IDENTIFIER_CHARSET = ALPHANUMERIC + UNDERSCORE
const REGULAR_INTEGER_CHARSET = DIGITS + UNDERSCORE
const HEX_INTEGER_CHARSET = HEX + UNDERSCORE
const BINARY_INTEGER_CHARSET = BINARY + UNDERSCORE


const ARITHMETIC_OPERATORS = "+-*/%"
const LOGICAL_OPERATORS = "!><="
const BITWISE_OPERATORS = "~&|^"

const ASSIGNMENT_OPERATORS = [
	"=",
	"+=",
	"-=",
	"*=",
	"/=",
	"%=",
	"&=",
	"|=",
	">>=",
	"<<=",
]

const EXPRESSION_OPERATORS = [
	# arithmetic
	"+",
	"-",
	"*",
	"/",
	"%",
	
	# logical
	"==",
	">=",
	"<=",
	"!=",
	"!",
	"&&",
	"||",
	
	# bitwise
	">>",
	"<<",
	"|",
	"&",
	"^",
	"~",
]


const OPERATOR_CHARS = (
	ARITHMETIC_OPERATORS
	+ LOGICAL_OPERATORS
	+ BITWISE_OPERATORS
)


const TERMINATING_CHARS = (
	SPACE 
	+ LINEBREAK 
	+ COMMA
	+ COLON
	+ WRAPPING_CHARS
)
