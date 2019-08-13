import
    strformat, tables, sequtils,
    ../parser/ast


type
    TObjectKind* = enum
        Integer
        String
        Boolean
        TNull
        ReturnValue
        Function
        Builtin
        Error

    Environment* = ref object of RootObj
        store: Table[string, Object]
        outer: Environment

    BuiltinFunction* = proc(args: seq[Object]): Object

    ObjectType* = enum
        INTEGER_OBJ = "INTEGER"
        STRING_OBJ = "STRING"
        BOOLEAN_OBJ = "BOOLEAN"
        NULL_OBJ = "NULL"
        RETURN_VALUE_OBJ = "RETURN_VALUE"
        FUNCTION_OBJ = "FUNCTION"
        BUILTIN_OBJ = "BUILTIN"
        ERROR_OBJ="ERROR_OBJ"

    Object* = ref TObject
    TObject = object
        case kind*: TObjectKind
        of Integer:
            IntValue*: int
        of String:
            StringValue*: string
        of Boolean:
            BoolValue*: bool
        of TNull:
            discard
        of ReturnValue:
            ReValue*: Object
        of Function:
            Parameters*: seq[PNode]
            Body*: BlockStatements
            Env*: Environment
        of Builtin:
            Fn*: BuiltinFunction
        of Error:
            ErrMessage*: string


proc inspect*(self: Object): string
proc myType*(self: Object): ObjectType


proc inspect*(self: Object): string =
    case self.kind:
    of Integer:
        result = $self.IntValue
    of String:
        result = $self.StringValue
    of Boolean:
        result = $self.BoolValue
    of TNull:
        result = "null"
    of ReturnValue:
        result = self.ReValue.inspect()
    of Function:
        var params: seq[string]
        for p in self.Parameters:
            params.add(p.astToString())
        # TODO:
        result = fmt"fn ({params}) " & "{" & fmt"{'\n'} {self.Body.astToString()} {'\n'}" & "}"
    of Builtin:
        result = "builtin function"
    of Error:
        result = fmt"ERROR: {self.ErrMessage}"


proc myType*(self: Object): ObjectType =
    case self.kind:
    of Integer:
        result = INTEGER_OBJ
    of String:
        result = STRING_OBJ
    of Boolean:
        result = BOOLEAN_OBJ
    of TNull:
        result = NULL_OBJ
    of ReturnValue:
        result = RETURN_VALUE_OBJ
    of Function:
        result = FUNCTION_OBJ
    of Builtin:
        result = BUILTIN_OBJ
    of Error:
        result = ERROR_OBJ


proc newEnvironment*(): Environment =
    Environment(store: initTable[string, Object](1)) # TODO: あってる？


proc get*(self: Environment, name: string): Object =
    if self == nil or self.store.len() == 0:
        result =  Object(kind: Error)
    elif self.store.hasKey(name):
        result = self.store[name]
    else:
        result = self.outer.get(name)


proc set*(self: Environment, name: string, val: Object) =
    self.store[name] = val


proc newEncloseEnvironment*(outer: Environment): Environment =
    result = newEnvironment()
    result.outer = outer
