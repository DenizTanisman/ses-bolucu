#!/bin/zsh
# Ses Bölücü helper: zips whose archive comment starts with "ses-bolucu"
# (set by the Ses Bölücü page) are extracted into "Ses Bölücü/" next to
# them (the folder is made when missing), then deleted. Other zips are left alone. Transcripts (.txt, same name) are made
# in the background with Whisper (mlx-whisper, on this Mac):
#   "ses-bolucu txt"         → for every file in the zip
#   "txt: <file>" lines      → only for those files
# Usage: ses-bolucu-unzip.sh [folder]   (default ~/Downloads)
setopt null_glob
# Folder actions run with a bare PATH; Whisper needs Homebrew's ffmpeg.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
dir="${1:-$HOME/Downloads}"
dir="${dir%/}"
whisper="$HOME/Library/Application Support/ses-bolucu/venv/bin/mlx_whisper"
model="mlx-community/whisper-large-v3-turbo"

for z in "$dir"/*.zip; do
  # `unzip -z` prints "Archive:  <path>" and then the archive comment.
  comment="$(unzip -z "$z" 2>/dev/null | tail -n +2)"
  [[ "$comment" == ses-bolucu* ]] || continue
  all_txt=0
  want=()
  for line in "${(@f)comment}"; do
    case "$line" in
      "ses-bolucu txt") all_txt=1 ;;
      "txt: "*) want+=("${line#txt: }") ;;
    esac
  done
  tmp=$(mktemp -d) || continue
  audio=()
  # Parts and their transcripts go into their own folder, made when missing.
  out="$dir/Ses Bölücü"
  mkdir -p "$out" || { rm -rf "$tmp"; continue; }
  # ditto (Archive Utility's engine) handles UTF-8 names like "Yeme-İçme";
  # macOS unzip fails on them.
  if ditto -x -k "$z" "$tmp"; then
    for f in "$tmp"/*(.); do
      name=${f:t}; base=${name:r}; ext=${name:e}
      target="$out/$name"; n=2
      while [[ -e "$target" || -e "$out/${target:t:r}.txt" ]]; do
        target="$out/$base-$n.$ext"; ((n++))
      done
      # Wanted? Compare by file, not by spelling: APFS lookups ignore
      # Unicode normalisation (ğ written as one or two code points).
      wanted=$all_txt
      for w in "${want[@]}"; do [[ "$tmp/$w" -ef "$f" ]] && wanted=1; done
      mv "$f" "$target" || continue
      (( wanted )) && audio+=("$target")
    done
    rm -f "$z"
  fi
  rm -rf "$tmp"

  if [[ -x "$whisper" && ${#audio} -gt 0 ]]; then
    # Background, so the folder action returns at once; one file at a time.
    (
      for a in "${audio[@]}"; do
        "$whisper" "$a" --model "$model" --output-format txt \
          --output-dir "${a:h}" --output-name "${a:t:r}" --verbose False
      done
    ) >/dev/null 2>&1 &!
  fi
done
