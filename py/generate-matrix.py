#!/usr/bin/env python3
"""
Generate build matrix for kernel compilation.
"""

import json
import os
import sys
from typing import Dict, List, Any
from copy import deepcopy

# Default template
DEFAULT = {
	"name": "Dummy",
	"KSU": "Dummy",
	"KSU_COMPAT": "false",
	"KSU_SUSFS": "false",
	"C_LTO": "false"
}

def config(**overrides) -> Dict[str, Any]:
	"""Create config from default with overrides."""
	cfg = deepcopy(DEFAULT)
	cfg.update(overrides)
	return cfg

# Build configurations
BUILD_CONFIGS: Dict[str, List[Dict[str, Any]]] = {
	"BUILD_VANILLA": [
		config(name="Vanilla", KSU="no"),
		config(name="Vanilla+NoLTO", KSU="vnlto")
	],
	"BUILD_KSU": [
		config(name="KSU", KSU="KSU")
	],
	"BUILD_KSUN": [
		config(name="KSUN", KSU="KSUN")
	],
	"BUILD_KSU_SUSFS": [
		config(name="KSU+SUSFS", KSU="KSU", KSU_SUSFS="true"),
		config(name="KSUN+SUSFS", KSU="KSUN", KSU_SUSFS="true"),
		config(name="Compat+KSU+SUSFS", KSU="KSU", KSU_COMPAT="true", KSU_SUSFS="true"),
		config(name="Compat+KSUN+SUSFS", KSU="KSUN", KSU_COMPAT="true", KSU_SUSFS="true"),
		config(name="Compat+LTO+KSUN+SUSFS", KSU="KSUN", KSU_COMPAT="true", KSU_SUSFS="true", C_LTO="true"),
		config(name="RSKSU+SUSFS", KSU="RSKSU", KSU_SUSFS="true")
	]
}

def get_env_bool(var_name: str, default: bool = False) -> bool:
	"""Read environment variable as boolean."""
	value = os.environ.get(var_name, "").strip().lower()
	if not value:
		return default
	return value in ("true", "1", "yes", "on")

def generate_matrix() -> Dict[str, List[Dict[str, Any]]]:
	"""Generate the matrix based on enabled build configurations."""
	entries = []

	for env_var, configs in BUILD_CONFIGS.items():
		if get_env_bool(env_var):
			entries.extend(configs)

	if not entries:
		raise ValueError(
			"No build configurations selected!"
			"Set at least one BUILD_* environment variable to 'true'."
		)

	return {"include": entries}

def main() -> None:
	"""Main entry point."""
	try:
		matrix = generate_matrix()
		print(f"matrix={json.dumps(matrix)}")

		print(f"::notice::Generated {len(matrix['include'])} build configurations", file=sys.stderr)

	except Exception as e:
		print(f"::error::Failed to generate matrix: {str(e)}", file=sys.stderr)
		sys.exit(1)

if __name__ == "__main__":
	main()
