#!/bin/zsh
# Installs the Ses Bölücü Mac helper:
#   1. Whisper (mlx-whisper, Apple Silicon) in its own venv
#   2. ses-bolucu-unzip.sh in ~/Library/Scripts
#   3. a folder action on ~/Downloads that runs it for every new item
# Remove: Finder › Downloads › right click › Quick Actions › Folder Actions
# Setup… › untick ses-bolucu-unzip.scpt (and delete the files below).
set -e
here="${0:A:h}"
support="$HOME/Library/Application Support/ses-bolucu"
scripts="$HOME/Library/Scripts"

command -v ffmpeg >/dev/null || { echo "ffmpeg gerekli: brew install ffmpeg"; exit 1; }
mkdir -p "$support" "$scripts/Folder Action Scripts"

if [[ ! -x "$support/venv/bin/mlx_whisper" ]]; then
  echo "Whisper kuruluyor…"
  if command -v uv >/dev/null; then
    uv venv -q "$support/venv" --python 3.12
    VIRTUAL_ENV="$support/venv" uv pip install -q mlx-whisper
  else
    python3 -m venv "$support/venv"
    "$support/venv/bin/pip" install -q mlx-whisper
  fi
fi

cp "$here/ses-bolucu-unzip.sh" "$scripts/ses-bolucu-unzip.sh"
chmod +x "$scripts/ses-bolucu-unzip.sh"
osacompile -o "$scripts/Folder Action Scripts/ses-bolucu-unzip.scpt" "$here/folder-action.applescript"

osascript <<'OSA'
tell application "System Events"
	set folder actions enabled to true
	set dl to POSIX path of (path to downloads folder)
	if not (exists folder action "Downloads") then make new folder action at end of folder actions with properties {name:"Downloads", path:dl}
	if not (exists script "ses-bolucu-unzip.scpt" of folder action "Downloads") then
		tell folder action "Downloads" to make new script at end of scripts with properties {name:"ses-bolucu-unzip.scpt"}
	end if
end tell
OSA
echo "Hazır. Ses Bölücü zip'leri İndirilenler'e düşünce açılır; istenirse yanına .txt metni eklenir."
echo "(Whisper modeli ilk kullanımda bir kez iner, ~1,5 GB.)"
