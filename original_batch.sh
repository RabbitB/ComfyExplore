#!/usr/bin/env bash
# batch_image_triage.sh
# Interactive batch triage for AI-generated images (finals in CWD, full-size in ./full_size)
# Requirements: bash 4+, GNU findutils, coreutils; optional ImageMagick "display" for viewing.

set -u

shopt -s nocaseglob

# -------- Config --------
FINAL_EXTS=(png jpg jpeg webp gif bmp tif tiff)
FULL_DIR="full_size"
RETAIN_DIR="retained"
RETAIN_FULL_DIR="$RETAIN_DIR/full_size"
TRASH_DIR="trash"
TRASH_FULL_DIR="$TRASH_DIR/full_size"
METADATA_DIR="metadata"

# -------- Helpers --------

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Gather final images in current directory, newest -> oldest, null-separated.
# Uses GNU find -printf with epoch mtime, sorts reverse numerically.
gather_final_images() {
  local -a find_args=()
  find_args=(. -maxdepth 1 -type f \( )
  local first=1
  for ext in "${FINAL_EXTS[@]}"; do
    if (( first )); then
      find_args+=(-iname "*.${ext}")
      first=0
    else
      find_args+=(-o -iname "*.${ext}")
    fi
  done
  find_args+=( \) -printf '%T@ %P\0' )

  # shellcheck disable=SC2207
  mapfile -d '' -t ALL_IMAGES < <(find "${find_args[@]}" 2>/dev/null | sort -zr -n -r | cut -z -d' ' -f2-)
}

# Convert 1-based index to label: 1..9 => "1".."9"; 10=>a, 11=>b, ... 35=>z, 36=>aa ...
index_to_label() {
  local n=$1
  if (( n <= 9 )); then
    printf '%d' "$n"
    return
  fi
  local m=$(( n - 10 ))  # 0-based into letter space
  local label=""
  while :; do
    local rem=$(( m % 26 ))
    # prepend letter
    label="$(printf "\\$(printf '%03o' $((97+rem)))")${label}"
    m=$(( m / 26 - 1 ))
    (( m < 0 )) && break
  done
  printf '%s' "$label"
}

# Convert label back to 1-based index; digits 1-9 or letters (a..z, aa..zz...)
label_to_index() {
  local s=$1
  if [[ $s =~ ^[1-9]$ ]]; then
    printf '%d' "$s"
    return
  fi
  if [[ $s =~ ^[a-z]+$ ]]; then
    local -i acc=0
    local c char
    for (( i=0; i<${#s}; i++ )); do
      char=${s:i:1}
      c=$(printf '%d' "'$char")
      c=$(( c - 97 ))   # a->0 .. z->25
      acc=$(( acc*26 + (c + 1) ))
    done
    acc=$(( acc - 1 ))  # back to 0-based m
    printf '%d' $(( acc + 10 ))
    return
  fi
  printf '%d' 0  # invalid
}

# Slice ALL_IMAGES into BATCH given count and number (newest first).
select_batch() {
  local count=$1
  local number=$2
  BATCH=()
  local total=${#ALL_IMAGES[@]}
  if (( count <= 0 || number <= 0 )); then
    return
  fi
  local offset=$(( (number - 1) * count ))
  if (( offset >= total )); then
    return
  fi
  local end=$(( offset + count - 1 ))
  (( end >= total )) && end=$(( total - 1 ))
  local i
  for (( i=offset; i<=end; i++ )); do
    BATCH+=("${ALL_IMAGES[i]}")
  done
}

# Build label maps for current BATCH
build_labels() {
  LABELS=()
  declare -gA LABEL_TO_IDX=()
  declare -gA IDX_TO_LABEL=()
  local i label
  for (( i=0; i<${#BATCH[@]}; i++ )); do
    label=$(index_to_label $(( i + 1 )))
    LABELS+=("$label")
    LABEL_TO_IDX["$label"]=$i
    IDX_TO_LABEL["$i"]="$label"
  done
}

print_batch_list() {
  echo
  echo "Batch contains ${#BATCH[@]} image(s):"
  local i label f size dims
  for (( i=0; i<${#BATCH[@]}; i++ )); do
    label=${IDX_TO_LABEL[$i]}
    f=${BATCH[$i]}
    size=$(du -h -- "${f}" 2>/dev/null | awk '{print $1}')
    if has_cmd identify; then
      dims=$(identify -format '%wx%h' -- "${f}" 2>/dev/null || echo "?x?")
    else
      dims="?x?"
    fi
    printf '  [%s] %s  (%s, %s)\n' "$label" "$f" "${dims}" "${size:-?}"
  done
  echo
  echo "Commands: <label> to select | v <label> to view image | m <label> to view metadata | M <label> to view raw metadata | r to refresh | t to empty trash | q to exit"
}

empty_trash() {
  echo
  # Check for files in trash dirs
  local has_any=0
  if [[ -d "$TRASH_DIR" ]]; then
    if find "$TRASH_DIR" -mindepth 1 -print -quit | read -r; then
      has_any=1
    fi
  fi
  if [[ $has_any -eq 0 && -d "$TRASH_FULL_DIR" ]]; then
    if find "$TRASH_FULL_DIR" -mindepth 1 -print -quit | read -r; then
      has_any=1
    fi
  fi
  if [[ $has_any -eq 0 ]]; then
    echo "Trash is empty.";
    return 0
  fi

  read -r -p "Move all files in ./${TRASH_DIR} to the system Trash? (y/N): " yn
  [[ ${yn,,} != "y" ]] && { echo "Cancelled."; return 1; }

  if has_cmd gio; then
    for d in "$TRASH_DIR" "$TRASH_FULL_DIR"; do
      [[ -d "$d" ]] || continue
      while IFS= read -r -d '' file; do
        gio trash -- "$file" 2>/dev/null || echo "Failed to trash: $file"
      done < <(find "$d" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
    done
    echo "Moved trash contents to system Trash via 'gio'."
    return 0
  elif has_cmd trash-put; then
    for d in "$TRASH_DIR" "$TRASH_FULL_DIR"; do
      [[ -d "$d" ]] || continue
      while IFS= read -r -d '' file; do
        trash-put -- "$file" 2>/dev/null || echo "Failed to trash: $file"
      done < <(find "$d" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
    done
    echo "Moved trash contents to system Trash via 'trash-put'."
    return 0
  elif has_cmd gvfs-trash; then
    for d in "$TRASH_DIR" "$TRASH_FULL_DIR"; do
      [[ -d "$d" ]] || continue
      while IFS= read -r -d '' file; do
        gvfs-trash -- "$file" 2>/dev/null || echo "Failed to trash: $file"
      done < <(find "$d" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
    done
    echo "Moved trash contents to system Trash via 'gvfs-trash'."
    return 0
  else
    read -r -p "No system trash tool found (gio/trash-put/gvfs-trash). Permanently delete trash contents? (y/N): " yn2
    [[ ${yn2,,} != "y" ]] && { echo "Cancelled."; return 1; }
    rm -rf -- "$TRASH_DIR"/* "$TRASH_FULL_DIR"/* 2>/dev/null && echo "Permanently removed trash contents." || echo "Failed to remove some items."
    return 0
  fi
}

# Ensure retained and trash directories exist.
ensure_retained_dirs() {
  mkdir -p -- "$RETAIN_DIR" "$RETAIN_FULL_DIR"
}

ensure_trash_dirs() {
  mkdir -p -- "$TRASH_DIR" "$TRASH_FULL_DIR"
}

ensure_metadata_dir() {
  mkdir -p -- "$METADATA_DIR"
}

keep_image() {
  local f="$1"
  ensure_retained_dirs
  local base
  base=$(basename -- "$f")
  local full="$FULL_DIR/$base"
  local dest_final="$RETAIN_DIR/$base"
  local dest_full="$RETAIN_FULL_DIR/$base"

  if mv -n -- "$f" "$dest_final"; then
    echo "Kept final -> $dest_final"
  else
    echo "Failed to move final (exists?): $dest_final"
  fi

  if [[ -f "$full" ]]; then
    if mv -n -- "$full" "$dest_full"; then
      echo "Kept full-size -> $dest_full"
    else
      echo "Failed to move full-size (exists?): $dest_full"
    fi
  else
    echo "Warning: Full-size not found: $full"
  fi
}

delete_image() {
  local f="$1"
  local base
  base=$(basename -- "$f")
  local full="$FULL_DIR/$base"

  ensure_trash_dirs
  local dest_final="$TRASH_DIR/$base"
  local dest_full="$TRASH_FULL_DIR/$base"

  if mv -n -- "$f" "$dest_final"; then
    echo "Trashed final: $dest_final"
  else
    echo "Failed to move final to trash (exists?): $dest_final"
  fi

  if [[ -f "$full" ]]; then
    if mv -n -- "$full" "$dest_full"; then
      echo "Trashed full-size: $dest_full"
    else
      echo "Failed to move full-size to trash (exists?): $dest_full"
    fi
  else
    echo "Note: Full-size not found: $full"
  fi
}

view_image() {
  local label=$1
  local idx=${LABEL_TO_IDX[$label]:-}
  [[ -z $idx ]] && { echo "Invalid label: $label"; return; }
  local f=${BATCH[$idx]}
  local base
  base=$(basename -- "$f")
  local full="$FULL_DIR/$base"
  local target="$f"

  # Prefer full-size if present
  if [[ -f "$full" ]]; then
    target="$full"
  fi

  if has_cmd display; then
    ( display -- "$target" ) &
    local disppid=$!
    wait $disppid 2>/dev/null || true
  elif has_cmd kitty; then
    kitty +kitten icat --transfer-mode=file "$target"
  elif has_cmd viu; then
    viu --animate --scale-down "$target"
  elif has_cmd xdg-open; then
    xdg-open -- "$target" >/dev/null 2>&1 &
  elif has_cmd gio; then
    gio open -- "$target" >/dev/null 2>&1 &
  else
    echo "No image viewer found; viewing disabled."
  fi
}

view_metadata() {
  local label=$1
  local idx=${LABEL_TO_IDX[$label]:-}
  [[ -z $idx ]] && { echo "Invalid label: $label"; return; }
  local f=${BATCH[$idx]}
  local base=$(basename -- "$f")
  local noext="${base%.*}"
  local full="$FULL_DIR/$base"
  local target="$f"
  [[ -f "$full" ]] && target="$full"

  echo "Inspecting embedded metadata for: $target"

  local TMPDIR
  TMPDIR=$(mktemp -d 2>/dev/null || true)
  if [[ -z ${TMPDIR:-} ]]; then
    echo "Failed to create temp dir"; return
  fi
  # ensure we clean up (use parameter expansion to avoid unbound var under set -u)
  trap 'rm -rf -- "${TMPDIR:-}"' RETURN

  # Helper to write an identified JSON blob (as raw) to TMPDIR/parsed.json
  # and to extract workflow/parameters into separate files if present.

  # 1) exiftool (best) -> JSON
  if has_cmd exiftool; then
    echo "Method: exiftool (scan for JSON blobs)"
    exiftool -json -- "$target" > "$TMPDIR/exif.json" 2>/dev/null || true
    # try to extract a JSON-like blob from exif output
    if grep -q '{' "$TMPDIR/exif.json" 2>/dev/null; then
      grep -Eo '\{[^\}]{20,}\}' "$TMPDIR/exif.json" | head -n1 > "$TMPDIR/parsed.json" 2>/dev/null || true
    fi
  fi

  # 2) PNG-specific python extractor
  local is_png=0
  if head -c 8 "$target" 2>/dev/null | grep -q $"\x89PNG\r\n\x1a\n" 2>/dev/null; then
    is_png=1
  elif [[ "${target,,}" == *.png ]]; then
    is_png=1
  fi

  if (( is_png )); then
    if has_cmd python3; then
      echo "Method: python3 PNG extractor (searching all text chunks for JSON)"
      python3 - <<'PY' "$target" "$TMPDIR"
import sys, struct, zlib, json, re, os
path = sys.argv[1]
outdir = sys.argv[2]
all_text = ''
with open(path,'rb') as f:
    sig = f.read(8)
    if sig != b"\x89PNG\r\n\x1a\n":
        sys.exit(2)
    while True:
        len_bytes = f.read(4)
        if len(len_bytes) < 4:
            break
        length = struct.unpack('>I', len_bytes)[0]
        ctype = f.read(4)
        data = f.read(length)
        crc = f.read(4)
        if ctype in (b'tEXt', b'iTXt', b'zTXt'):
            try:
                if ctype == b'tEXt':
                    key, val = data.split(b'\x00',1)
                    text = val.decode('utf-8', errors='replace')
                elif ctype == b'zTXt':
                    key, rest = data.split(b'\x00',1)
                    if rest:
                        comp = rest[1:]
                        try:
                            text = zlib.decompress(comp).decode('utf-8', errors='replace')
                        except Exception:
                            text = rest.decode('utf-8', errors='replace')
                    else:
                        text = ''
                else:
                    parts = data.split(b'\x00',5)
                    if len(parts) >= 6:
                        comp_flag = parts[1]
                        text_field = parts[5]
                        if comp_flag == b'1':
                            try:
                                text = zlib.decompress(text_field).decode('utf-8', errors='replace')
                            except Exception:
                                text = text_field.decode('utf-8', errors='replace')
                        else:
                            text = text_field.decode('utf-8', errors='replace')
                    else:
                        text = data.decode('utf-8', errors='replace')
                all_text += '\n' + text
            except Exception:
                pass
    # find all JSON-like blobs
    found = False
    for m in re.finditer(r'([\[{].*?[\]}])', all_text, flags=re.S):
        blob = m.group(1)
        try:
            parsed = json.loads(blob)
            with open(os.path.join(outdir,'parsed.json'),'w',encoding='utf-8') as of:
                json.dump(parsed, of, indent=2, ensure_ascii=False)
            def find_key(obj,key):
                if isinstance(obj, dict):
                    if key in obj:
                        return obj[key]
                    for v in obj.values():
                        res = find_key(v,key)
                        if res is not None:
                            return res
                elif isinstance(obj, list):
                    for item in obj:
                        res = find_key(item,key)
                        if res is not None:
                            return res
                return None
            wf = find_key(parsed,'workflow')
            if wf is not None:
                with open(os.path.join(outdir,'workflow.json'),'w',encoding='utf-8') as wfout:
                    json.dump(wf, wfout, indent=2, ensure_ascii=False)
            params = find_key(parsed,'parameters')
            if params is not None:
                with open(os.path.join(outdir,'parameters.json'),'w',encoding='utf-8') as pf:
                    json.dump(params, pf, indent=2, ensure_ascii=False)
            found = True
            break
        except Exception:
            continue
    if not found:
        # try strings fallback
        try:
            import subprocess
            out = subprocess.check_output(['strings','-n','8',path], stderr=subprocess.DEVNULL, universal_newlines=True)
            m = re.search(r'([\[{].*[\]}])', out, flags=re.S)
            if m:
                blob = m.group(1)
                try:
                    parsed = json.loads(blob)
                    with open(os.path.join(outdir,'parsed.json'),'w',encoding='utf-8') as of:
                        json.dump(parsed, of, indent=2, ensure_ascii=False)
                    wf = find_key(parsed,'workflow')
                    if wf is not None:
                        with open(os.path.join(outdir,'workflow.json'),'w',encoding='utf-8') as wfout:
                            json.dump(wf, wfout, indent=2, ensure_ascii=False)
                    params = find_key(parsed,'parameters')
                    if params is not None:
                        with open(os.path.join(outdir,'parameters.json'),'w',encoding='utf-8') as pf:
                            json.dump(params, pf, indent=2, ensure_ascii=False)
                except Exception:
                    pass
        except Exception:
            pass
PY
    return
  else
    echo "python3 not found — falling back to strings-based search for JSON blobs in PNG."
    echo "Method: strings grep"
    strings -n 8 -- "$target" | grep -Eo '\{[^\}]{20,}\}' | head -n 1 > "$TMPDIR/parsed.json" 2>/dev/null || true
    return
  fi
  fi

  # At this point, parsed.json may exist. If not, try identify for generic metadata
  if [[ ! -f "$TMPDIR/parsed.json" && $(has_cmd identify; echo $?) -eq 0 ]]; then
    echo "Method: identify -verbose"
    identify -verbose -- "$target" > "$TMPDIR/identify.txt" 2>/dev/null || true
    # try to extract JSON-like from identify output
    grep -Eo '\{[^\}]{20,}\}' "$TMPDIR/identify.txt" | head -n1 > "$TMPDIR/parsed.json" 2>/dev/null || true
  fi

  # Now present found info: parameters must always be shown when present
  if [[ -f "$TMPDIR/parameters.json" ]]; then
    echo
    echo "--- Parameters (from embedded metadata) ---"
    if has_cmd jq; then
      jq . "$TMPDIR/parameters.json" | sed 's/^/  /'
    else
      cat "$TMPDIR/parameters.json" | sed 's/^/  /'
    fi
    echo
    read -r -p "Save parameters to file? (y/N): " savep
    if [[ ${savep,,} == y ]]; then
      ensure_metadata_dir
      local outp="$METADATA_DIR/${noext}.parameters.json"
      cp -n -- "$TMPDIR/parameters.json" "$outp" && echo "Saved parameters -> $outp" || echo "Failed to save (exists?): $outp"
    fi
  elif [[ -f "$TMPDIR/parsed.json" ]]; then
    # Try to extract parameters key from parsed.json
    if has_cmd jq; then
      if jq 'has("parameters")' "$TMPDIR/parsed.json" >/dev/null 2>&1 && [[ $(jq 'has("parameters")' "$TMPDIR/parsed.json") == "true" ]]; then
        echo
        echo "--- Parameters (from parsed JSON) ---"
        jq .parameters "$TMPDIR/parsed.json" | sed 's/^/  /'
        echo
        read -r -p "Save parameters to file? (y/N): " savep
        if [[ ${savep,,} == y ]]; then
          ensure_metadata_dir
          local outp="$METADATA_DIR/${noext}.parameters.json"
          jq .parameters "$TMPDIR/parsed.json" > "$outp" && echo "Saved parameters -> $outp" || echo "Failed to save -> $outp"
        fi
      fi
    else
      # no jq: try to grep 'parameters' textually
      if grep -q '"parameters"' "$TMPDIR/parsed.json" 2>/dev/null; then
        echo
        echo "--- Parameters (raw snippet) ---"
        grep -n '"parameters"' -n "$TMPDIR/parsed.json" || true
        echo
        read -r -p "Save parsed JSON to file so you can inspect parameters? (y/N): " savep
        if [[ ${savep,,} == y ]]; then
          ensure_metadata_dir
          local outp="$METADATA_DIR/${noext}.parsed.json"
          cp -n -- "$TMPDIR/parsed.json" "$outp" && echo "Saved parsed JSON -> $outp" || echo "Failed to save -> $outp"
        fi
      fi
    fi
  else
    echo "No structured parameters found in metadata."
  fi

  # Workflow: offer to view or save
  if [[ -f "$TMPDIR/workflow.json" ]]; then
    echo
    echo "Workflow JSON found."
    read -r -p "View workflow now? (y/N): " vieww
    if [[ ${vieww,,} == y ]]; then
      if has_cmd jq; then
        jq . "$TMPDIR/workflow.json" | less -R
      else
        cat "$TMPDIR/workflow.json" | less -R
      fi
    fi
    read -r -p "Save workflow to file? (y/N): " savew
    if [[ ${savew,,} == y ]]; then
      ensure_metadata_dir
      local outw="$METADATA_DIR/${noext}.workflow.json"
      cp -n -- "$TMPDIR/workflow.json" "$outw" && echo "Saved workflow -> $outw" || echo "Failed to save (exists?): $outw"
    fi
  else
    # Maybe parsed.json contains a workflow key
    if [[ -f "$TMPDIR/parsed.json" && $(has_cmd jq; echo $?) -eq 0 ]]; then
      if jq 'has("workflow")' "$TMPDIR/parsed.json" >/dev/null 2>&1 && [[ $(jq 'has("workflow")' "$TMPDIR/parsed.json") == "true" ]]; then
        echo
        echo "Workflow found inside parsed JSON."
        read -r -p "View workflow now? (y/N): " vieww
        if [[ ${vieww,,} == y ]]; then
          jq .workflow "$TMPDIR/parsed.json" | less -R
        fi
        read -r -p "Save workflow to file? (y/N): " savew
        if [[ ${savew,,} == y ]]; then
          ensure_metadata_dir
          local outw="$METADATA_DIR/${noext}.workflow.json"
          jq .workflow "$TMPDIR/parsed.json" > "$outw" && echo "Saved workflow -> $outw" || echo "Failed to save -> $outw"
        fi
      fi
    fi
  fi

  # cleanup handled by trap
}

batch_menu() {
  local done_count=0
  while :; do
    # Remove any entries that no longer exist in CWD (processed elsewhere)
    local i kept=()
    for (( i=0; i<${#BATCH[@]}; i++ )); do
      [[ -f ${BATCH[$i]} ]] && kept+=("${BATCH[$i]}")
    done
    BATCH=("${kept[@]}")
    build_labels

    if (( ${#BATCH[@]} == 0 )); then
      echo "Batch complete (all images saved or deleted)."
      return 0
    fi

    print_batch_list
    read -r -p "> " cmd rest

    case "${cmd,,}" in
      M)
        # Forced/raw metadata
        read -r -a parts <<< "$rest"
        if [[ ${#parts[@]} -eq 0 ]]; then
          echo "Usage: M <label>"
          continue
        fi
        view_metadata_raw "${parts[0],,}"
        ;;
      t)
        empty_trash || true
        continue
        ;;
      m)
        # "m <label>"
        read -r -a parts <<< "$rest"
        if [[ ${#parts[@]} -eq 0 ]]; then
          echo "Usage: m <label>"
          continue
        fi
        view_metadata "${parts[0],,}"
        ;;
      q)
        return 1
        ;;
      r|"")
        continue
        ;;
      v)
        # "v <label>"
        read -r -a parts <<< "$rest"
        if [[ ${#parts[@]} -eq 0 ]]; then
          echo "Usage: v <label>"
          continue
        fi
        view_image "${parts[0],,}"
        ;;
      *)
        # assume label
        local label="${cmd,,}"
        local idx=${LABEL_TO_IDX[$label]:-}
        if [[ -z $idx ]]; then
          echo "Invalid input. Use a label (e.g., 1, a) or commands v/r/q."
          continue
        fi
        local f="${BATCH[$idx]}"
        image_menu "$f" || true
        ;;
    esac
  done
}

image_menu() {
  local f="$1"
  while :; do
    echo
    echo "Selected: $f"
    echo "Actions: (k) keep | (d) delete | (b) back"
    read -r -p "(k/d/b): " action
    case "${action,,}" in
      k)
        keep_image "$f"
        return 0
        ;;
      d)
        read -r -p "Confirm delete both final and full-size? (y/N): " yn
        if [[ ${yn,,} == "y" ]]; then
          delete_image "$f"
          return 0
        fi
        ;;
      b|"")
        return 0
        ;;
      *)
        echo "Invalid choice."
        ;;
    esac
  done
}

prompt_positive_int() {
  local prompt="$1"
  local val
  while :; do
    read -r -p "$prompt" val
    [[ ${val,,} == q ]] && echo "q" && return 0
    if [[ $val =~ ^[1-9][0-9]*$ ]]; then
      echo "$val"
      return 0
    fi
    echo "Enter a positive integer, or q to quit."
  done
}

# -------- Main loop --------

echo "AI Image Batch Triage"
echo "Folder (finals): $(pwd)"
echo "Full-size folder: ./${FULL_DIR}"
echo "Retained folders: ./${RETAIN_DIR}, ./${RETAIN_FULL_DIR}"
echo "Trash folders: ./${TRASH_DIR}, ./${TRASH_FULL_DIR}"
has_cmd display && echo "Viewer: ImageMagick 'display' available (use 'v <label>')" || echo "Viewer: disabled (no 'display')"
echo

trap 'echo; echo "Exiting."; exit 0' INT

while :; do
  gather_final_images
  total=${#ALL_IMAGES[@]}
  if (( total == 0 )); then
    echo "No final images found in current directory."
    read -r -p "Press Enter to retry, or type q to quit: " resp
    [[ ${resp,,} == q ]] && break
    continue
  fi

  bc_val=$(prompt_positive_int "Batch count (q to quit): ")
  [[ $bc_val == q ]] && break
  bn_val=$(prompt_positive_int "Batch number (q to quit): ")
  [[ $bn_val == q ]] && break

  BATCH=()
  select_batch "$bc_val" "$bn_val"

  if (( ${#BATCH[@]} == 0 )); then
    echo "No images in that batch (total images: $total)."
    continue
  fi

  build_labels
  if batch_menu; then
    # finished batch
    :
  else
    # user chose to exit from batch menu
    read -r -p "Exit program? (y/N): " yn
    [[ ${yn,,} == y ]] && break
  fi
done

echo "Done."
