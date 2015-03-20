/* lexical grammar */
%lex
LBR    \r\n|\r|\n
%options flex
%options ranges

%%

\s+                  						/* ignore whitespace */


"("						return '(';
")"						return ')';

"+"						return '+';
"-"						return '-';
"*"						return '*';
"/"						return '/';
"="						return '=';
"!="					return '!=';
"<>"					return '<>';
"<="					return '<=';
"<"						return '<';
">="					return '>=;';
">"						return '>';
","						return ',';


\'(\'\'|[^\'])*\'		%{
							yytext = yytext.substr(1, yyleng - 2);
							return 'STRING';
						%}

\"(\"\"|[^\"])*\"		%{
							yytext = yytext.substr(1, yyleng - 2);
							return 'IDENTIFIER';
						%}

[a-zA-Z][0-9a-zA-Z_]*	return make_keyword_or_identifier(yytext);
[1-9][0-9]*				return 'POSITIVE_INT';
[1-9][0-9]*\.([0-9]*)?	return 'POSITIVE_FLOAT';


"//".*					/* ignore comment */

<<EOF>>					/* return 'EOF' */

/lex

%left OR
%left AND
%right NOT

%left '==' '!=' '<>' '<' '<=' '>' '>='
%left '+' '-'
%left '*' '/'

%start Expressions

%%

PositiveInteger
	: POSITIVE_INT
		{ $$ = +(yytext); }
	;

Identifier
	: IDENTIFIER
		{ $$ = yytext; }
	;

TypeToken
	: INT
		{
			$$ = {
				type: 'int',
				length: 4
			};
		}
	| VARCHAR '(' PositiveInteger ')'
		{
			$$ = {
				type: 'varchar',
				length: $3
			};
		}
	;

ColumnDef
	: IDENTIFIER TypeToken
		{
			$$ = {
				type: 'ColumnDef',
				column_name: $1,
				column_type: $2
			};
		}
	;

ColumnDefList
	: ColumnDef
		{
			$$ = [$1];
		}
	| ColumnDefList ',' ColumnDef
		{
			$$ = $1;
			$$.push($3);
		}
	;

CreateStmt
	: CREATE TABLE Identifier '(' ColumnDefList ')'
		{
			$$ = {
				type: 'CreateStmt',
				table_name: $3,
				column_defs: $5
			};
		}
	;

IdentifierList
	: Identifier
		{
			$$ = [$1];
		}
	| IdentifierList ',' Identifier
		{
			$$ = $1;
			$$.push($3);
		}
	;

Number
	: POSITIVE_INT
		{ $$ = +($1); }
	| '-' POSITIVE_INT
		{ $$ = -($1); }
	| POSITIVE_FLOAT
		{ $$ = +($1); }
	| '-' POSITIVE_FLOAT
		{ $$ = +($1); }
	;

String
	: STRING
		{ $$ = $1.replace(/''/g, "'"); }
	;

Value
	: Number
		{ $$ = $1; }
	| String
		{ $$ = $1; }
	;

ValueList
	: Value
		{
			$$ = [$1];
		}
	| ValueList ',' Value
		{
			$$ = $1;
			$$.push($3);
		}
	;

InsertStmt
	: INSERT INTO Identifier '(' IdentifierList ')' VALUES '(' ValueList ')'
		{
			$$ = {
				type: 'InsertStmt',
				table_name: $3,
				column_names: $5,
				values: $9
			};
		}
	;

Expr
	: Identifier
		{
			$$ = {
				type: 'Expr',
				sub_type: 'identifier',
				value: $1
			};
		}
	| String
		{
			$$ = {
				type: 'Expr',
				sub_type: 'string',
				value: $1
			};
		}
	| Number
		{
			$$ = {
				type: 'Expr',
				sub_type: 'number',
				value: $1
			};
		}
	| Identifier '(' ExprList ')'
		{
			$$ = {
				type: 'Expr',
				sub_type: 'function',
				function_name: $1,
				function_args: $3
			};
		}
	| '(' Expr ')'
		{
			$$ = $2;
		}
	| Expr '+' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '-' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '*' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '/' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	;

ExprList
	: Expr
		{
			$$ = [$1];
		}
	| ExprList ',' Expr
		{
			$$ = $1;
			$$.push($3);
		}
	;

CompareExpr
	: Expr '=' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '!=' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '<>' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '>=' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '>' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '<=' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr '<' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				left: $1,
				right: $3
			};
		}
	| Expr IS NULL
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'is_null',
				value: $1
			};
		}
	| Expr IS NOT NULL
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'not_is_null',
				value: $1
			};
		}
	| Expr NOT IS NULL
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'not_is_null',
				value: $1
			};
		}
	;

LogicExpr
	: CompareExpr
		{
			$$ = $1;
		}
	| '(' LogicExpr ')'
		{
			$$ = $2;
		}
	| LogicExpr AND LogicExpr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: 'and',
				left: $1,
				right: $3
			}
		}
	| LogicExpr OR LogicExpr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: 'or',
				left: $1,
				right: $3
			}
		}
	| NOT LogicExpr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'not',
				value: $2
			}
		}
	;

opt_AS
	:
	| AS
	;

opt_OUTER
	:
	| OUTER
	;

JoinQulifier
	: INNER
		{ $$ = 'inner'; }
	| LEFT opt_OUTER
		{ $$ = 'left outer'; }
	| RIGHT opt_OUTER
		{ $$ = 'right outer'; }
	;

JoinCond
	: ON LogicExpr
		{ $$ = $1; }
	;

SubQuery
	: Identifier
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'single',
				query: $1,
				table_alias: null
			};
		}
	| Identifier opt_AS Identifier
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'single',
				query: $1,
				table_alias: $3
			};
		}
	| '(' SelectStmt ')'
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'query',
				query: $2,
				table_alias: null
			};
		}
	| '(' SelectStmt ')' opt_AS Identifier
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'query',
				query: $2,
				table_alias: $4
			};
		}
	;

SubQueryList
	: SubQuery
		{
			$$ = [$1];
		}
	| SubQueryList ',' SubQuery
		{
			$$ = $1;
			$$.push({
				type: 'Join',
				sub_type: 'cross',
				query: $3
			});
		}
	| SubQueryList CROSS JOIN SubQuery
		{
			$$ = $1;
			$$.push({
				type: 'Join',
				sub_type: 'cross',
				query: $4
			});
		}
	| SubQueryList JoinQulifier SubQuery JoinCond
		{
			$$ = $1;
			$$.push({
				type: 'Join',
				sub_type: $2,
				query: $3,
				cond: $4
			});
		}
	| SubQueryList JOIN SubQuery JoinCond
		{
			$$ = $1;
			$$.push({
				type: 'Join',
				sub_type: 'inner',
				query: $3,
				cond: $4
			});
		}
	;

WhereClause
	:
		{
			$$ = null;
		}
	| WHERE LogicExpr
		{
			$$ = $2;
		}
	;

GroupbyClause
	:
		{
			$$ = null;
		}
	;

Orderby
	: Identifier 
		{
			$$ = {
				type: 'Orderby',
				name: $1,
				asc: true
			};
		}
	| Identifier ASC
		{
			$$ = {
				type: 'Orderby',
				name: $1,
				asc: true
			};
		}
	| Identifier DESC
		{
			$$ = {
				type: 'Orderby',
				name: $1,
				asc: false
			};
		}
	;

OrderbyList
	: Orderby
		{
			$$ = [$1];
		}
	| OrderbyList ',' Orderby
		{
			$$ = $1;
			$$.push($3);
		}
	;

OrderbyClause
	: ORDER BY OrderbyList
		{
			$$ = $3;
		}
	;

OutputList
	: '*'
		{
			$$ = {
				type: '*'
			};
		}
	| ExprList
		{
			$$ = $1;
		}
	| '*' ',' ExprList
		{
			$$ = [ { type: '*' }, $3 ];
		}
	;


SelectStmt
	: SELECT OutputList
		{
			$$ = {
				type: 'SelectStmt',
				output_list: $2
			};
		}
	| SELECT OutputList FROM SubQueryList WhereClause OrderbyClause
		{
			$$ = {
				type: 'SelectStmt',
				output: $2,
				from: $4,
				where: $5,
				orderby: $6
			};
		}
	;

Expressions
	: CreateStmt
		{ return $1; }
	| InsertStmt
		{ return $1; }
	| SelectStmt
		{ return $1; }
	;

%%

function make_keyword_or_identifier(token) {
	var utoken = token.toUpperCase();

	switch (utoken) {
		case 'AND':
		case 'AS':
		case 'ASC':
		case 'BY':
		case 'CREATE':
		case 'CROSS':
		case 'DELETE':
		case 'DESC':
		case 'DROP':
		case 'FROM':
		case 'INNER':
		case 'INSERT':
		case 'INT':
		case 'INTO':
		case 'IS':
		case 'JOIN':
		case 'LEFT':
		case 'NOT':
		case 'NULL':
		case 'ON':
		case 'OR':
		case 'ORDER':
		case 'OUTER':
		case 'RIGHT':
		case 'SELECT':
		case 'TABLE':
		case 'UPDATE':
		case 'VALUES':
		case 'VARCHAR':
		case 'WHERE':
			return utoken;
		default:
			return 'IDENTIFIER';
	}
}
