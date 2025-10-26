#!/usr/bin/env bash
[[ "$RUNNER_DEBUG" == 1 ]] && set -x

set -euo pipefail

action="${INPUT_ACTION?}"
pkgname="${INPUT_PKGNAME?}"

function group() {
  echo ::group::"$*"
}
function endgroup() {
  echo ::endgroup::
}

push=false
validate=false
updatePkgsums=false

case "$action" in
  validate)
    validate=true
    ;;
  publish)
    push=true
    ssh_private_key="${INPUT_AUR_SSH_PRIVATE_KEY?}"
    git_email="${INPUT_AUR_EMAIL?}"
    git_username="${INPUT_AUR_USERNAME?}"
    ;;
  updatePkgsums)
    updatePkgsums=true
    ;;
  *)
    echo "Invalid action: $action, can only be 'validate' or 'publish'"
    exit 1
    ;;
esac

sudo chown -R "$USER" "$pkgname"
if [[ -v GITHUB_OUTPUT ]]; then
  sudo chown -R "$USER" "$GITHUB_OUTPUT"
fi

cd "$pkgname"

updatedPkgsums=false
if grep -q source= PKGBUILD; then
  group Updating checksums
  cp PKGBUILD PKGBUILD_old
  trap "rm $PWD/PKGBUILD_old" EXIT
  updpkgsums
  if ! git diff --exit-code --quiet PKGBUILD_old PKGBUILD; then
    updatedPkgsums=true
  fi
  if [[ -v GITHUB_OUTPUT ]]; then
    echo updated=$updatedPkgsums | tee -a "$GITHUB_OUTPUT"
  fi
  endgroup
fi

if [[ "$push" = true ]]; then
  group Configuring SSH
  ssh-keyscan -v aur.archlinux.org | tee -a "$HOME/.ssh/known_hosts"
  echo "$ssh_private_key" >"$HOME/.ssh/id_ed25519"
  chmod -v 0600 "$HOME/.ssh/id_ed25519"
  endgroup
fi

if [[ "$push" = true ]]; then
  group Configuring GIT
  git config --global user.name "$git_username"
  git config --global user.email "$git_email"
  endgroup
fi

group Cloning existing AUR package
url=aur.archlinux.org/$pkgname.git
if [[ -v ssh_private_key ]]; then
  git clone -v "ssh://aur@$url" /tmp/local-repo
else
  git clone -v "https://$url" /tmp/local-repo
fi
endgroup

group Copying package files
rsync -avv --include-from=<(git ls-files) --exclude='*' --filter='P .git' --delete-excluded ./ /tmp/local-repo/
endgroup

cd /tmp/local-repo

if [[ "$validate" == true ]] || [[ "$updatePkgsums" == true && "$updatedPkgsums" == true ]]; then
  group Updating archlinux-keyring
  sudo pacman -S --noconfirm --needed archlinux-keyring
  endgroup

  group Testing PKGBUILD
  (
    set +eu
    source ./PKGBUILD
    set -eu
    if [[ -v makedepends && "${#makedepends[@]}" -gt 0 ]]; then
      paru --sync --needed --asdeps --noconfirm "${makedepends[@]}"
    fi
    makepkg -d
  )
  endgroup
fi

group Generating .SRCINFO
makepkg --printsrcinfo | tee .SRCINFO
endgroup

if [[ "$push" == true ]] && ! git diff-index --quiet HEAD; then
  group Committing changes
  git add . -f
  git commit -m "chore: sync from github"
  endgroup

  group Pushing changes
  git push
  endgroup
fi
