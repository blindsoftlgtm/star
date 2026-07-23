#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAR_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROVIDER_ROOT="$STAR_ROOT/provider"
PYTHON_COMMAND="${PYTHON_COMMAND:-python3}"

declare -A PROVIDERS=()

echo "Finding configured STAR providers..."
echo

while IFS= read -r -d '' config; do
	script="${config%.ini}.py"
	if [[ -f "$script" ]]; then
		PROVIDERS["$script"]=1
	fi
done < <(find "$PROVIDER_ROOT" -type f -name '*.ini' -print0)

# Include Python providers from this checkout that are already running.
while IFS= read -r -d '' script; do
	if pgrep -f -- "python(3)? .*${script##*/}" >/dev/null 2>&1; then
		PROVIDERS["$script"]=1
	fi
done < <(find "$PROVIDER_ROOT" -type f -name '*.py' -print0)

if [[ ${#PROVIDERS[@]} -eq 0 ]]; then
	echo "No configured or running STAR providers were found."
	exit 1
fi

restarted=0
for script in "${!PROVIDERS[@]}"; do
	directory="$(dirname -- "$script")"
	filename="$(basename -- "$script")"

	while IFS= read -r pid; do
		[[ -n "$pid" && "$pid" != "$$" ]] && kill "$pid" 2>/dev/null || true
	done < <(pgrep -f -- "python(3)? .*$filename" || true)

	(
		cd -- "$directory"
		nohup "$PYTHON_COMMAND" -u "$filename" >provider.log 2>provider-error.log </dev/null &
	)

	echo "${filename%.py}: restarted"
	((restarted += 1))
done

echo
echo "$restarted STAR provider(s) restarted and reconnecting."
