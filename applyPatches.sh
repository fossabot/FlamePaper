#!/bin/bash

PS1="$"
basedir=`pwd`
echo "Rebuilding Forked projects.... "

function applyPatch {
    what=$1
    target=$2
    branch=$3
    cd "$basedir/$what"
    git fetch
    git reset --hard "$branch"
    git branch -f upstream >/dev/null

    cd "$basedir"
    if [ ! -d  "$basedir/$target" ]; then
        git clone $1 $target -b upstream
    fi
    cd "$basedir/$target"
    echo "Resetting $target to $what..."
    git remote rm upstream 2>/dev/null 2>&1
    git remote add upstream ../$what >/dev/null 2>&1
    git checkout master >/dev/null 2>&1
    git fetch upstream >/dev/null 2>&1
    git reset --hard upstream/upstream
    echo "  Applying patches to $target..."
    git am --abort
    git am --3way "$basedir/${what}-Patches/"*.patch
    if [ "$?" != "0" ]; then
        echo "  Something did not apply cleanly to $target."
        echo "  Please review above details and finish the apply then"
        echo "  save the changes with rebuildPatches.sh"
        exit 1
    else
        echo "  Patches applied cleanly to $target"
    fi
}

echo
echo "Applying SpigotMC patches to CraftBukkit and Bukkit"
echo
cd ../Bukkit
hash=$(git rev-parse HEAD)
git branch -f spigot "$hash"
applyPatch Bukkit Spigot-API origin/spigot && applyPatch CraftBukkit Spigot-Server origin/patched
echo
echo "Applying PaperSpigot patches to Spigot-Server and Spigot-API"
echo
applyPatch Spigot-API PaperSpigot-API && applyPatch Spigot-Server PaperSpigot-Server
echo
echo "Applying FlamePaper patches to PaperSpigot-Server and PaperSpigot-API"
echo
applyPatch PaperSpigot-Server FlamePaper-Server && applyPatch PaperSpigot-API FlamePaper-API