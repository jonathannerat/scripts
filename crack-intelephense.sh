#!/bin/sh

libfile="$1" # node_modules/intelephense/lib/intelephense.js
workdir="$(mktemp -d)"

trap "rm -r $workdir" EXIT

# Split libfile to optimize following sed edits
sed 's/;/;\n/g' "$libfile" > "$workdir/split.js"

# Searches for the function where the activation occurs, and saves the
# licenceKey provided by the user
SED_SAVE_LICENCE_KEY='/activate(e,t){/ s/\(const n=new\)/const licenceKey=t;\1/'

# Instead of checking the success code returned by the server,
# return a successful response with the user provided licenceKey
SED_RETURN_LICENCE_KEY='/Failed to activate key/ s/200.*Failed to activate key"))/e({statusCode:200,data:{message:{licenceKey,resultCode:1}}})/'

# Remove signature verification of the successful response
SED_REMOVE_VERIFICATION='/set activationResult/ s/d\.verify(e)&&//'

# Perform previous operations on the split file
sed -i -e "$SED_SAVE_LICENCE_KEY" \
       -e "$SED_RETURN_LICENCE_KEY" \
       -e "$SED_REMOVE_VERIFICATION" \
    "$workdir/split.js"

# Remove shebang
tail -n+2 "$workdir/split.js" > "$workdir/no-shebang.js"

# Delete newlines
tr -d '\n' < "$workdir/no-shebang.js" > "$workdir/join.js"

# add shebang back
echo '#!/usr/bin/env node' | cat - "$workdir/join.js" > "$workdir/cracked.js"

backup="${1%%.js}.bak.js"

cp "$libfile" "$backup"

mv "$workdir/cracked.js" "$libfile"
chmod +x "$libfile"

echo "Cracked intelephense!"
