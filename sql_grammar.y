/* lexical grammar */
%lex
LBR    \r\n|\r|\n
%options flex
%options ranges

%%

\s+                  						/* ignore whitespace */

\'(\'\'|[^\'])*\'		%{
							yytext = yytext.substr(1, yyleng - 2);
							return 'STRING';
						%}

\"(\"\"|[^\"])*\"		%{
							yytext = yytext.substr(1, yyleng - 2);
							return 'IDENTIFIER';
						%}

[a-zA-Z][0-9a-zA-Z_]*	return make_keyword_or_identifier(yytext);
\d+\.\d*				return 'NON_NEGTIVE_FLOAT1';
\.\d+					return 'NON_NEGTIVE_FLOAT2';
[1-9]\d*				return 'POSITIVE_INT';
\d+						return 'NON_NEGTIVE_INT';

"//".*					/* ignore comment */

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
"."						return '.';
","						return ',';

<<EOF>>					/* return 'EOF' */

/lex

%expect n

%left OR								/* prec: 10 */
%left AND								/* prec: 20 */
%right NOT								/* prec: 30 */

%left '=' '!=' '<>' '<' '<=' '>' '>=', 'IS'	/* prec: 40 */
%left '+' '-'								/* prec: 50 */
%left '*' '/'								/* prec: 60 */

%start Expressions

%%

PositiveInteger
	: POSITIVE_INT
		{ $$ = +(yytext); }
	;

Identifier
	: IDENTIFIER
		{
			$$ = yytext;
		}
	;

TypeToken
	: INT
		{
			$$ = {
				type: 'int',
				length: 4,
				norm_text: function () {
					return "int";
				}
			};
		}
	| VARCHAR '(' PositiveInteger ')'
		{
			$$ = {
				type: 'varchar',
				length: $3,
				norm_text: function () {
					return "varchar(" + this.length + ")";
				}
			};
		}
	;

ColumnDef
	: IDENTIFIER TypeToken
		{
			$$ = {
				type: 'ColumnDef',
				column_name: $1,
				column_type: $2,
				norm_text: function () {
					return this.column_name + " " + this.column.type;
				}
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
				column_defs: $5,
				norm_text: function () {
					return "CREATE TABLE " + this.table_name + " (" + norm_array(this.column_defs) + ")";
				}
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
	| NON_NEGTIVE_INT
		{ $$ = +($1); }
	| '-' NON_NEGTIVE_INT
		{ $$ = -($1); }
	| NON_NEGTIVE_FLOAT1
		{ $$ = +($1); }
	| '-' NON_NEGTIVE_FLOAT1
		{ $$ = +($1); }
	| NON_NEGTIVE_FLOAT2
		{ $$ = +($1); }
	| '-' NON_NEGTIVE_FLOAT2
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
				values: $9,
				norm_text: function () {
					return "INSERT INTO " + this.table_name + " (" + this.column_names.join(",") + ") VALUES (" + this.values.join(",") + ")";
				}
			};
		}
	;

Expr
	: Identifier
		{
			$$ = {
				type: 'Expr',
				sub_type: 'identifier',
				value: $1,
				norm_text: function () { return this.value; }
			};
		}
	| Identifier '.' Identifier
		{
			$$ = {
				type: 'Expr',
				sub_type: 'identifier2',
				value1: $1,
				value2: $3,
				norm_text: function () { return this.value1 + "." + this.value2; }
			};
		}
	| String
		{
			$$ = {
				type: 'Expr',
				sub_type: 'string',
				value: $1,
				norm_text: function () { return "'" + escape_string(this.value) + "'"; }
			};
		}
	| Number
		{
			$$ = {
				type: 'Expr',
				sub_type: 'number',
				value: $1,
				norm_text: function () { return this.value; }
			};
		}
	| Identifier '(' ExprList ')'
		{
			$$ = {
				type: 'Expr',
				sub_type: 'function',
				function_name: $1,
				function_args: $3,
				norm_text: function () { return this.function_name + "(" + norm_array(this.function_args) + ")"; }
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
				prec: 50,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '-' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 50,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '*' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 60,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '/' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 60,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
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
				prec: 40,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '!=' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 40,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '<>' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 40,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '>=' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 40,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '>' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 40,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '<=' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 40,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr '<' Expr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: $2,
				prec: 40,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| Expr IS NULL
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'IS_NULL',
				prec: 40,
				value: $1,
				norm_text: function () {
					return this.value.norm_text() + " IS NULL";
				}
			};
		}
	| Expr IS NOT NULL
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'NOT_IS_NULL',
				prec: 40,
				value: $1,
				norm_text: function () {
					return this.value.norm_text() + " IS NOT NULL";
				}
			};
		}
	| Expr NOT IS NULL
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'NOT_IS_NULL',
				prec: 40,
				value: $1,
				norm_text: function () {
					return this.value.norm_text() + " IS NOT NULL";
				}
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
				op: 'AND',
				prec: 20,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| LogicExpr OR LogicExpr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'binary_op',
				op: 'OR',
				prec: 10,
				left: $1,
				right: $3,
				norm_text: function () { return norm_expr(this.left, this.prec) + " " + this.op + " " + norm_expr(this.right, this.prec) }
			};
		}
	| NOT LogicExpr
		{
			$$ = {
				type: 'Expr',
				sub_type: 'unary_op',
				op: 'NOT',
				prec: 30,
				value: $2,
				norm_text: function () {
					return "NOT " + norm_expr(this.value);
				}
			};
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
		{
			$$ = {
				type: 'JoinCond',
				value: $2,
				norm_text: function () {
					return "ON " + this.value.norm_text();
				}
			};
		}
	;

SubQuery
	: Identifier
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'single',
				query: $1,
				table_alias: null,
				norm_text: function () {
					return this.query;
				}
			};
		}
	| Identifier opt_AS Identifier
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'single',
				query: $1,
				table_alias: $3,
				norm_text: function () {
					return this.query + " AS " + this.table_alias;
				}
			};
		}
	| '(' SelectStmt ')'
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'query',
				query: $2,
				table_alias: null,
				norm_text: function () {
					return "(" + this.query.norm_text() + ")";
				}
			};
		}
	| '(' SelectStmt ')' opt_AS Identifier
		{
			$$ = {
				type: 'SubQuery',
				sub_type: 'query',
				query: $2,
				table_alias: $4,
				norm_text: function () {
					return "(" + this.query.norm_text() + ") AS " + this.table_alias;
				}
			};
		}
	;

SubQueryList
	: SubQuery
		{
			$$ = $1;
		}
	| '(' SubQueryList ')'
		{
			$$ = $2;
		}
	| SubQueryList ',' SubQuery
		{
			$$ = {
				type: 'Join',
				sub_type: 'cross',
				query1: $1,
				query2: $3,
				norm_text: function () {
					return this.query1.norm_text() + " JOIN " + this.query2.norm_text();
				}
			};
		}
	| SubQueryList CROSS JOIN SubQuery
		{
			$$ = {
				type: 'Join',
				sub_type: 'cross',
				query1: $1,
				query2: $4,
				norm_text: function () {
					return this.query1.norm_text() + " JOIN " + this.query2.norm_text();
				}
			};
		}
	| SubQueryList JoinQulifier JOIN SubQuery JoinCond
		{
			$$ = {
				type: 'Join',
				sub_type: $2,
				query1: $1,
				query2: $4,
				cond: $5,
				norm_text: function () {
					return this.query1.norm_text() + " " + this.sub_type + " " + this.query2.norm_text() + " ON " + this.cond.norm_text();
				}
			};
		}
	| SubQueryList JOIN SubQuery JoinCond
		{
			$$ = {
				type: 'Join',
				sub_type: 'inner',
				query1: $1,
				query2: $3,
				cond: $4,
				norm_text: function () {
					return this.query1.norm_text() + " JOIN " + this.query2.norm_text() + " ON " + this.cond.norm_text();
				}
			};
		}
	;

WhereClause
	: WHERE LogicExpr
		{
			$$ = {
				type: 'WhereClause',
				value: $2,
				norm_text: function () {
					return "WHERE " + this.value.norm_text();
				}
			};
		}
	;

GroupbyClause
	: GROUP BY Identifier
		{
			$$ = {
				type: 'GroupbyClause',
				value: $3,
				norm_text: function () {
					return "GROUP BY " + this.value.norm_text();
				}
			};
		}
	;

Orderby
	: Identifier 
		{
			$$ = {
				type: 'Orderby',
				name: $1,
				asc: true,
				norm_text: function () { return this.name.norm_text(); }
			};
		}
	| Identifier ASC
		{
			$$ = {
				type: 'Orderby',
				name: $1,
				asc: true,
				norm_text: function () { return this.name.norm_text(); }
			};
		}
	| Identifier DESC
		{
			$$ = {
				type: 'Orderby',
				name: $1,
				asc: false,
				norm_text: function () { return this.name.norm_text() + " DESC"; }
			};
		}
	;

OrderbyList
	: Orderby
		{
			$$ = {
				type: 'OrderbyList',
				values: [$1],
				norm_text: function () {
					return this.values.join(",");
				}
			};
		}
	| OrderbyList ',' Orderby
		{
			$$ = {
				type: 'OrderbyList',
				values: $1.concat($3),
				norm_text: function () {
					return this.values.join(",");
				}
			};
		}
	;

OrderbyClause
	: ORDER BY OrderbyList
		{
			$$ = {
				type: 'OrderbyClause',
				value: $3,
				norm_text: function () {
					return "ORDER BY " + this.value.norm_text();
				}
			};
		}
	;

OutputList
	: '*'
		{
			$$ = {
				type: 'output_list',
				values: [{
					type: 'star',
					norm_text: function () { return "*"; }
				}]
			};
		}
	| ExprList
		{
			$$ = {
				type: 'output_list',
				values: [].concat($1),
				norm_text: function () {
					return norm_array(this.values);
				}
			};
		}
	| '*' ',' ExprList
		{
			$$ = {
				type: 'output_list',
				values: [{
					type: 'star',
					norm_text: function () { return "*"; }
				}].concat($3),
				norm_text: function () {
					return norm_array(this.values);
				}
			};
		}
	;


SelectStmt
	: SELECT OutputList
		{
			$$ = {
				type: 'SelectStmt',
				output: $2,
				norm_text: function () {
					return "SELECT " + this.output.norm_text();
				}
			};
		}
	| SELECT OutputList FROM SubQueryList
		{
			$$ = {
				type: 'SelectStmt',
				output: $2,
				from: $4,
				where: null,
				groupby: null,
				orderby: null,
				norm_text: function () {
					return "SELECT " + this.output.norm_text() + " FROM " + this.from.norm_text();
				}
			};
		}
	| SELECT OutputList FROM SubQueryList WhereClause
		{
			$$ = {
				type: 'SelectStmt',
				output: $2,
				from: $4,
				where: $5,
				groupby: null,
				orderby: null,
				norm_text: function () {
					return "SELECT " + this.output.norm_text() + " FROM " + this.from.norm_text() + " WHERE " + this.where.norm_text();
				}
			};
		}
	| SELECT OutputList FROM SubQueryList WhereClause OrderbyClause
		{
			$$ = {
				type: 'SelectStmt',
				output: $2,
				from: $4,
				where: $5,
				groupby: null,
				orderby: $6,
				norm_text: function () {
					return "SELECT " + this.output.norm_text() + " FROM " + this.from.norm_text() + " WHERE " + this.where.norm_text()
						+ " ORDER BY " + this.orderby.norm_text();
				}
			};
		}
	| SELECT OutputList FROM SubQueryList WhereClause GroupbyClause OrderbyClause
		{
			$$ = {
				type: 'SelectStmt',
				output: $2,
				from: $4,
				where: $5,
				groupby: $6,
				orderby: $7,
				norm_text: function () {
					return "SELECT " + this.output.norm_text() + " FROM " + this.from.norm_text() + " WHERE " + this.where.norm_text()
						+ " GROUP BY " + this.groupby.norm_text() + " ORDER BY " + this.orderby.norm_text();
				}
			};
		}
	| SELECT OutputList FROM SubQueryList OrderbyClause
		{
			$$ = {
				type: 'SelectStmt',
				output: $2,
				from: $4,
				where: null,
				groupby: null,
				orderby: $5,
				norm_text: function () {
					return "SELECT " + this.output.norm_text() + " FROM " + this.from.norm_text() + " ORDER BY " + this.orderby.norm_text();
				}
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

function escape_string(val) {
	return val.replace("'", "''");
}

function norm_array(arr) {
	return arr.map(function (item) {
		return item.norm_text();
	}).join(",");
}

function norm_expr (expr_obj, prec) {
	var text = expr_obj.norm_text();
	return expr_obj.prec && prec && prec > expr_obj.prec ? "(" + text + ")" : text;
}
