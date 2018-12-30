import ast
import ../lexer/lexer
import ../lexer/token
import sequtils, strformat


type Parser* = ref object of RootObj
    l: Lexer
    curToken: Token
    peekToken: Token
    errors: seq[string]

proc nextToken(self: Parser) =
        self.curToken = self.peekToken
        self.peekToken = self.l.nextToken()

proc curTokenIs(self: Parser, t: TokenType): bool = self.curToken.Type == t
proc peekTokenIs(self: Parser, t: TokenType): bool = self.peekToken.Type == t

proc peekError(self: Parser, t: token.TokenType) =
    let msg = fmt"expected next tokent to be {t}, got {self.peekToken.Type} instead"
    self.errors.add(msg)

proc expectPeek(self: Parser, t: token.TokenType): bool =
    if self.peekTokenIs(t):
        self.nextToken()
        return true
    else:
        self.peekError(t)
        return false


proc parseLetStatement(self: Parser): Statement =
    var statement = Statement(kind: LetStatement, Token: self.curToken)

    # ident
    if not self.expectPeek(token.IDENT): return Statement(kind: Nil)
    statement.Name = Identifier(
                        Token: self.curToken,
                        Value: self.curToken.Literal
                     )

    # =
    if not self.expectPeek(token.ASSIGN): return Statement(kind: Nil)

    # ~ ;
    while not self.curTokenIs(token.SEMICOLON):
        self.nextToken()

    statement

proc parseReturnStatement(self: Parser): Statement =
    var statement = Statement(kind: ReturnStatement, Token: self.curToken)
    self.nextToken()

    # ~ ;
    while not self.curTokenIs(token.SEMICOLON):
        self.nextToken()

    statement


proc parseStatement(self: Parser): Statement =
    case self.curToken.Type
    of token.LET:
        return self.parseLetStatement()
    of token.RETURN:
        return self.parseReturnStatement()
    # else:
    #     return cast[None](0)

# create AST Root Node
proc parseProgram*(self: Parser): Program =
    var program = Program()
    program.statements = newSeq[Statement]()

    while self.curToken.Type != token.EOF:
        let statement = self.parseStatement()
        if statement.kind != Nil:
            program.statements.add(statement)
        self.nextToken()

    program

proc newParser*(l: Lexer): Parser =
    let p = Parser(l: l, errors: newSeq[string]())
    p.nextToken()
    p.nextToken()
    p


# = debug ===============

proc astToString*(self: Program): string =
    var o: string
    for statement in self.statements:
        # o = o & statement.astToString()
        discard

    return o


# proc astToString(self: Statement): string =
#     var o: string
#     if self.kind == LetStatement:
#         # let name = <expression>;
#         o = self.tokenLiteral() & " " & self.Name.Value & "="
#         # o = fmt"{self.tokenLiteral()} {self.Name.astToString()} = "
#         return o

#     elif self.kind == ReturnStatement:
#         # return hoge;
#         o = self.tokenLiteral() & " "
#         self.ReturnValue.astToString()
#         o = o & ";"
#         # o = fmt"{self.tokenLiteral()}  "
#         return o

#     elif self.kind == ExpressionStatement:
#         # if self.Exception
#         return self.Expression.astToString()
#         # return ""



proc error*(self: Parser): seq[string] = self.errors


proc main() = discard

when isMainModule:
    main()
