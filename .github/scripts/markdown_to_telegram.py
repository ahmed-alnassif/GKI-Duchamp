#!/usr/bin/env python3

import re
import sys

SPECIAL = r"\_*[]()~`>#+-=|{}.!"


def escape(text):
	return re.sub(r"([\\_*[\]()~`>#+\-=|{}.!])", r"\\\1", text)


def convert(text):
	tokens = re.split(r"(`[^`\n]*`|\[[^\]\n]+\]\([^)]+\))", text)

	for i, token in enumerate(tokens):
		if token.startswith("`") and token.endswith("`"):
			tokens[i] = r"\`" + escape(token[1:-1]) + r"\`"

		elif token.startswith("[") and "](" in token:
			match = re.fullmatch(r"\[([^\]]+)\]\(([^)]+)\)", token)
			if match:
				label, url = match.groups()
				tokens[i] = f"[{escape(label)}]({url})"
			else:
				tokens[i] = escape(token)

		elif not token.startswith("`") and not token.startswith("["):
			tokens[i] = escape(token)

	return "".join(tokens)


def main():
	if len(sys.argv) != 2:
		print(f"Usage: {sys.argv[0]} <markdown-file>", file=sys.stderr)
		sys.exit(1)

	with open(sys.argv[1], encoding="utf-8") as file:
		sys.stdout.write(convert(file.read()))


if __name__ == "__main__":
	main()