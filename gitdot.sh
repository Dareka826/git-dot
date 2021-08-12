#!/bin/sh

OLD_DIR="$(pwd)"
[ "$1" ] && cd "$1"

printf "digraph git {\n"

git show-ref --heads --tags | while IFS= read -r ref; do
	target=$(echo $ref | cut -d' ' -f1)
	ref_name=$(echo $ref | grep -Eo "[^/]+$")

	if [ "$(echo $ref | grep -Eo " refs/tags/[^/]+$")" = " refs/tags/$ref_name" ]; then
		# It's a tag
		target_n=$(git rev-parse $ref_name^{})
		if [ "$target" != "$target_n" ]; then
			# Annotated tag
			printf "%s\n" "    \"$target\" -> \"$target_n\";"
		fi
	fi

	printf "%s\n" "    \"$ref_name\" [shape=note];"
	printf "%s\n" "    \"$ref_name\" -> \"$target\";"
done

printf "\n"

{
    git rev-list --objects --all --filter=object:type=commit
    git rev-list --objects --filter=object:type=commit \
		$(git fsck --unreachable --no-reflogs 2>/dev/null \
			| grep '^unreachable commit ' | cut -d' ' -f3)
} \
	| sort | uniq | cut -d' ' -f1 | while IFS= read -r obj; do
		obj_data=$(git cat-file -p $obj)
		parent=$(echo "$obj_data" | grep -E "^parent [a-zA-Z0-9]+$" | awk '{ print $2 }')
		obj_hash_short=$(echo $obj | cut -c1-10)

		if [ "$parent" ]; then
			printf "%s\n" "    \"$obj\" [shape=box style=filled label=\"$obj_hash_short\"];"
			printf "%s\n" "    \"$obj\" -> \"$parent\";"
		else
			printf "%s\n" "    \"$obj\" [shape=oval style=filled label=\"$obj_hash_short\"];"
		fi
	done

printf "}\n"

cd "$OLD_DIR"
