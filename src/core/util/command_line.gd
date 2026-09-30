class_name CommandLine
extends RefCounted
## Splits a console line into tokens. Supports "double quoted" arguments.


static func tokenize(line: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var current := ""
	var in_quotes := false
	for ch: String in line.strip_edges():
		if ch == "\"":
			in_quotes = not in_quotes
		elif ch == " " and not in_quotes:
			if not current.is_empty():
				tokens.append(current)
				current = ""
		else:
			current += ch
	if not current.is_empty():
		tokens.append(current)
	return tokens
