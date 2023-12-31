grammar ScriptLanguage;

scriptLanguage: variableAssign* terminalExpr;

variableAssign:   ID ':=' numericExpr ';' #numericAssign
                | ID ':=' booleanExpr ';' #booleanAssign
                ;

terminalExpr : 'return' booleanExpr ';';

booleanExpr: '(' booleanExpr ')'                                                              #parenthesisBooleanExpr
            | 'boolIf' booleanExpr  'then'  booleanExpr  'else'  booleanExpr                  #conditionalBooleanExpr
            | ID                                                                              #booleanVariable
            | numericExpr op=('<'|'>'|'<='|'>=') numericExpr                                  #numericRelational
            | numericExpr op=('=='|'!=') numericExpr                                          #numericEquality
            | booleanExpr op=('<==>'|'<!=>') booleanExpr                                      #booleanEquality
            | booleanExpr 'and' booleanExpr                                                   #andComparison
            | booleanExpr 'or' booleanExpr                                                    #orComparison
            ;

fileConstant: 'FileA' | 'FileB' | 'FileC' | 'FileD' |
              'FileE' | 'FileF' | 'FileG' | 'FileH';
rankConstant: 'Rank1' | 'Rank2' | 'Rank3' | 'Rank4' |
              'Rank5' | 'Rank6' | 'Rank7' | 'Rank8';

numericExpr: '(' numericExpr ')'                                                                #parenthesisNumericExpr
              | 'numIf'  booleanExpr 'then' numericExpr 'else' numericExpr                      #conditionalNumericExpr
              | 'abs(' numericExpr ')'                                                          #absoluteNumericExpr
              | numericExpr '%' numericExpr                                                     #moduloNumericExpr
              | numericExpr op=('+'|'-') numericExpr                                            #plusMinusNumericExpr
              | NumericLitteral                                                                 #litteralNumericExpr
              | ID                                                                              #numericVariable
              | fileConstant                                                                    #fileConstantNumericExpr
              | rankConstant                                                                    #rankConstantNumericExpr
              ;

NumericLitteral: [0-9]+;
ID: [a-zA-Z][a-zA-Z0-9_]*;
COMMENT
: '/*' .*? '*/' -> skip
;
LINE_COMMENT
: '//' ~[\r\n]* -> skip
;

WS : [ \t\r\n]+ -> skip;