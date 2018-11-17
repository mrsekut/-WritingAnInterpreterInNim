import tables
type TokenType* = string

type Token* = ref object of RootObj
    Type*: TokenType
    Literal*: string

const
    ILLEGAL* = "ILLEGAL"
    EOF* = "EOF"

    IDENT* = "IDENT"
    INT* = "INT"

    ASSIGN* = "="
    PLUS* = "+"
    MINUS* = "-"
    BANG* = "!"
    ASTERISC* = "*"
    SLASH* = "/"

    LT* = "<"
    GT* =" >"

    COMMA* = ","
    COLON* = ":"

    LPAREN* = "("
    RPAREN* = ")"
    LBRACE* = "{"
    RBRACE* = "}"

    PROC* = "PROC"
    LET* = "LET"
    TRUE* = "TRUE"
    FALSE* = "FALSE"
    IF* = "IF"
    ELSE* = "ELSE"
    RETURN* = "RETURN"


var keywords = {
    "proc": PROC,
    "let": LET,
    "true": TRUE,
    "false": FALSE,
    "if": IF,
    "else": ELSE,
    "return": RETURN
    }.newTable


proc LookUpIdent*(ident: string): TokenType =
    if keywords.hasKey(ident):
        return keywords[ident]
    return IDENT