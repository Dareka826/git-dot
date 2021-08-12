#!/bin/sh

OLD_DIR="$(pwd)"
[ "$1" ] && cd "$1"

# Begin the graph
printf "digraph git {\n"

# Add refs to the graph
git show-ref --heads --tags | while IFS= read -r ref; do
	target=$(echo $ref | cut -d' ' -f1) # What the ref points to
	ref_name=$(echo $ref | grep -Eo "[^/]+$") # Just the name

	target_n=$(git rev-parse $ref_name^{}) # What the ref ultimately points to
	# Check if the ref is a symbolic one
	if [ "$target" != "$target_n" ]; then
		# Connect the target and the dereferenced target
		printf "%s\n" "    \"$target\" -> \"$target_n\";"
	fi

	# Add the ref to the graph
	printf "%s\n" "    \"$ref_name\" [shape=note];"
	printf "%s\n" "    \"$ref_name\" -> \"$target\";"
done

printf "\n"

# For all commits in object database
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

		# Check if the commit has a parent
		if [ "$parent" ]; then
			# If yes, make it a box and connect it to its parent
			printf "%s\n" "    \"$obj\" [shape=box style=filled label=\"$obj_hash_short\"];"
			printf "%s\n" "    \"$obj\" -> \"$parent\";"
		else
			# Otherwise, make it an oval
			printf "%s\n" "    \"$obj\" [shape=oval style=filled label=\"$obj_hash_short\"];"
		fi
	done

# End the graph
printf "}\n"

cd "$OLD_DIR"
