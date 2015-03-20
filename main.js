
var parser = require('./sql_grammar');

var execute = function (str) {
	var p = new parser.Parser();
	try {
		node = p.parse(str);
		console.log(JSON.stringify(node, null, '    '));
	} catch (e) {
		console.log(e);
	}
};

var readline = require('readline');
var rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout
});

rl.setPrompt('sql> ');
rl.prompt();

var lines = [];

rl.on('line', function (line) {
	var m = /^(.*);\s*$/.exec(line);

	if (m) {
		lines.push(m[1]);
		execute(lines.join('\n'));
		lines = [];
		rl.prompt();
	} else {
		lines.push(line);
	}
});

rl.on('close', function () {
	console.log('Bye!');
	process.exit(0);
});
