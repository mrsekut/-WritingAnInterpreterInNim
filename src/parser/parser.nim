import
    ast, typetraits, sequtils, strformat, typetraits, tables, strutils,
    ../lexer/lexer, ../lexer/token


# type
#     PrefixTypes = enum
#         PrPlus,
#         PrMinus,
#         PrNot

#     InfixTypes = enum
#         InPlus,
#         InMinus,
#         InDivide,
#         InMultiply,
#         InEq,
#         InNot_Eq,
#         InGt,
#         InLT


#     Precedence = enum
#         Lowest,
#         Equals,
#         Lg,
#         Sum,
#         Product,
#         Prefix,
#         Call

type
    Parser* = ref object of RootObj
        l: Lexer
        curToken: Token
        peekToken: Token
        errors: seq[string]

proc tokenToPrecedence(tok: Token): Precedence

proc newParser*(l: Lexer): Parser
proc nextToken(self: Parser)
proc curTokenIs(self: Parser, t: TokenType): bool
proc peekTokenIs(self: Parser, t: TokenType): bool
proc expectPeek(self: Parser, t: token.TokenType): bool
proc peekPrecedence(self: Parser): Precedence
proc curPrecedence(self: Parser): Precedence

proc parseLetStatement(self: Parser): PNode
proc parseReturnStatement(self: Parser): PNode
proc parseIdentifier(self: Parser): PNode
proc parseIntegerLiteral(self: Parser): PNode
proc parsePrefixExpression(self: Parser): PNode
proc parseInfixExpression(self: Parser, left: PNode): PNode # TODO: type

proc parseExpressionStatement(self: Parser): PNode
proc parseStatement(self: Parser): PNode
proc parseExpression(self: Parser, precedence: Precedence): PNode

proc parseProgram*(self: Parser): Program
proc error*(self: Parser): seq[string]
proc noPrefixParseError(self: Parser)
proc peekError(self: Parser, t: token.TokenType)

# implementation

proc tokenToPrecedence(tok: Token): Precedence =
    case tok.Type
    of EQ, NOT_EQ: return Precedence.Equals
    of LT, GT: return Precedence.Lg
    of PLUS, MINUS: return Precedence.Sum
    of SLASH, ASTERISC: return Precedence.Product
    else: return Precedence.Lowest

proc newParser*(l: Lexer): Parser =
    result = Parser(l: l, errors: newSeq[string]())
    result.nextToken()
    result.nextToken()

proc nextToken(self: Parser) =
    self.curToken = self.peekToken
    self.peekToken = self.l.nextToken()

proc curTokenIs(self: Parser, t: TokenType): bool =
    self.curToken.Type == t

proc peekTokenIs(self: Parser, t: TokenType): bool =
    self.peekToken.Type == t

proc expectPeek(self: Parser, t: token.TokenType): bool =
    if self.peekTokenIs(t):
        self.nextToken()
        return true
    else:
        self.peekError(t)
        return false

proc peekPrecedence(self: Parser): Precedence =
    result = tokenToPrecedence(self.curToken)

proc curPrecedence(self: Parser): Precedence =
    result = tokenToPrecedence(self.curToken)

# parse
proc parseLetStatement(self: Parser): PNode =
    result = PNode(kind: nkLetStatement, Token: self.curToken)

    # ident
    if not self.expectPeek(token.IDENT): return PNode(kind: Nil)
    result.Name = PNode(
                    kind: nkIdent,
                    Token: self.curToken,
                    IdentValue: self.curToken.Literal
                  )

    # =
    if not self.expectPeek(token.ASSIGN): return PNode(kind: Nil)

    # ~ ;
    while not self.curTokenIs(token.SEMICOLON):
        self.nextToken()

proc parseReturnStatement(self: Parser): PNode =
    result = PNode(kind: nkReturnStatement, Token: self.curToken)
    self.nextToken()

    # ~ ;
    while not self.curTokenIs(token.SEMICOLON):
        self.nextToken()

proc parseIdentifier(self: Parser): PNode =
    PNode(
        kind: nkIdent,
        Token: self.curToken,
        IdentValue: self.curToken.Literal)

proc parseIntegerLiteral(self: Parser): PNode =
    PNode(
        kind: nkIntegerLiteral,
        Token: self.curToken,
        IntValue: self.curToken.Literal.parseInt)

# NOTE: B
proc parsePrefixExpression(self: Parser): PNode =
    # var prefix: PrefixTypes
    # case self.curToken.Token.Type
    # of token.BANG: prefix = PrefixTypes.PrNot
    # of token.MINUS: prefix = PrefixTypes.PrMinus
    # else: discard


    let prefix = self.curToken.Token
    self.nextToken()

    let right = self.parseExpression(Precedence.Prefix)
    PNode(
        kind: nkPrefixExpression,
        Token: prefix, # TODO:
        Right: right
    )

# NOTE: C
proc parseInfixExpression(self: Parser, left: PNode): PNode =
    # var infix: InfixTypes
    # case self.curToken
    # of PLUS: infix = InfixTypes.PLUS
    # of MINUS: infix = InfixTypes.MINUS
    # of SLASH: infix = InfixTypes.DIVIDE
    # of ASTERISC: infix = InfixTypes.MULTIPLY
    # of EQUALS: infix = InfixTypes.EQ
    # of NOT_EQ: infix = InfixTypes.NOT_EQ
    # of GT: infix = InfixTypes.GT
    # of LT: infix = InfixTypes.LT
    # else: discard

    echo "in C ", left.Token.Literal

    let p = self.curPrecedence()
    self.nextToken()

    let right = self.parseExpression(p)
    PNode(
        kind: nkInfixExpression,
        # Token: infix, TODO:
        Token: self.curToken,
        InLeft: left,
        InRight: right
    )

# NOTE: A
proc parseExpression(self: Parser, precedence: Precedence): PNode =
    echo "in A 1"
    # prefix
    var left: PNode
    case self.curToken.Token.Type
    of IDENT: left = self.parseIdentifier()
    of INT: left = self.parseIntegerLiteral()
    of BANG, MINUS: left = self.parsePrefixExpression()
    else:
        left = nil
        self.noPrefixParseError()

    echo "in A ", repr(left)

    # infix
    # TODO: この辺だ。
    while not self.peekTokenIs(SEMICOLON) and precedence < self.peekPrecedence():
        echo "in while 1"
        case self.curToken.Type
        # case self.peekToken.Type
        of PLUS, MINUS, SLASH, ASTERISC, EQ, NOT_EQ, LT, GT:
            echo "in while 2"
            self.nextToken()
            left = self.parseInfixExpression(left) # `+`をparseするときに引数のleftがnilになっている
        else:
            echo "else"
            return left

    left

# NOTE: S
proc parseExpressionStatement(self: Parser): PNode =
    let statement = self.parseExpression(Precedence.Lowest)
    # if self.parseExpression(Precedence.Lowest).type.name == "PNode":
    if self.peekTokenIs(SEMICOLON):
        self.nextToken()
    echo "in S ", repr(statement)
    return statement


# // NOTE: Z
proc parseStatement(self: Parser): PNode =
    case self.curToken.Type
    of token.LET: return self.parseLetStatement()
    of token.RETURN: return self.parseReturnStatement()
    else: return self.parseExpressionStatement()

# create AST Root Node
proc parseProgram*(self: Parser): Program =
    result = Program()
    result.statements = newSeq[PNode]()

    while self.curToken.Type != token.EOF:
        let statement = self.parseStatement()
        # echo repr( statement ) NOTE:
        result.statements.add(statement)
        self.nextToken()


proc error*(self: Parser): seq[string] = self.errors

proc noPrefixParseError(self: Parser) =
    self.errors.add(fmt"no prefix parse function for {self.curToken.Type}")

proc peekError(self: Parser, t: token.TokenType) =
    let msg = fmt"expected next tokent to be {t}, got {self.peekToken.Type} instead"
    self.errors.add(msg)


proc main() = #discard

    type Test = object
        input: string
        leftValue: int
        operator: string
        rightValue: int

    let testInputs = @[
        Test(input: """6 + 5\0""", leftValue: 5, operator: "+", rightValue: 5),
        # Test(input: """5 - 5\0""", leftValue: 5, operator: "-", rightValue: 5),
        # Test(input: """5 * 5\0""", leftValue: 5, operator: "*", rightValue: 5),
        # Test(input: """5 / 5\0""", leftValue: 5, operator: "/", rightValue: 5),
        # Test(input: """5 > 5\0""", leftValue: 5, operator: ">", rightValue: 5),
        # Test(input: """5 < 5\0""", leftValue: 5, operator: "<", rightValue: 5),
        # Test(input: """5 == 5\0""", leftValue: 5, operator: "==", rightValue: 5),
        # Test(input: """5 != 5\0""", leftValue: 5, operator: "!=", rightValue: 5)
    ]

    for i in testInputs:
        let l = newLexer(i.input)
        let p = newParser(l)
        let program = p.parseProgram()

        echo program.statements.len

        let exp = program.statements[0]
        # check(testIntegerLiteral(exp.InLeft.IntValue, i.leftValue)) # TODO: Left
        # check(exp.Token.Type == i.operator)
        # check(testIntegerLiteral(exp.InRight.IntValue, i.rightValue))

when isMainModule:
    main()
