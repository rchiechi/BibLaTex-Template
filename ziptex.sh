#!/bin/bash

# If you use a custom class file, put it here
CUSTOM_CLASS="${HOME}/Documents/work/Manuscripts/BibLaTex-Template/rcclab.cls"

#SET OUTPUT AND TMP DIRECTORY#####
OUTDIR="${HOME}/Desktop/"
TMPDIR="LaTeX"

# MISC
LC_CTYPE=C
BASENAME=$(basename "$PWD")

##########################
RED=$(tput setaf 1 2>/dev/null)
GREEN=$(tput setaf 2 2>/dev/null)
YELLOW=$(tput setaf 3 2>/dev/null)
LIME_YELLOW=$(tput setaf 190 2>/dev/null)
POWDER_BLUE=$(tput setaf 153 2>/dev/null)
BLUE=$(tput setaf 4 2>/dev/null)
#MAGENTA=$(tput setaf 5 2>/dev/null)
#CYAN=$(tput setaf 6 2>/dev/null)
#WHITE=$(tput setaf 7 2>/dev/null)
#BRIGHT=$(tput bold 2>/dev/null)
#BLINK=$(tput blink 2>/dev/null)
#REVERSE=$(tput smso 2>/dev/null)
#UNDERLINE=$(tput smul 2>/dev/null)
RS=$(tput sgr0 2>/dev/null)

#######################

#
# NOTE: May not work if filenames have spaces in them!
#

usage() {
  echo "${LIME_YELLOW}Usage: $0 [ -f] [ -z ] [ -j ] [ -o OUTDIR ] .tex <.tex> ... ${RS}"
}

exit_abnormal() {
  usage
  exit 1
}

finddeps() {
  pdflatex -draft -record -halt-on-error "$1" >/dev/null
  awk '!x[$0]++' "${1%.tex}.fls" | sed '/^INPUT \/.*/d' | sed '/^OUTPUT .*/d' | sed '/^PWD .*/d' | sed 's/^INPUT //g'
}

checktex() { # This function should only be called from $TMPDIR
  TMPLOG="/tmp/ziptex.log"
  local __texok=0
  for TEX in "${TEXFILES[@]}"; do
    if pdflatex -draft -halt-on-error "${TEX}" > "$TMPLOG"; then
      echo "${GREEN}${TEX} is OK.${RS}"
    else
      echo "${RED}${TEX} is NOT OK.${RS}"
      cat "$TMPLOG"
      __texok=1
    fi
  done
  rm "$TMPLOG"
  return $__texok
}

catclass() { # This function should only be called from $TMPDIR
  echo "${BLUE}Looking for cls files to concatenate.${RS}"
  # Check for CUSTOM_CLASS
  [[ -z ${CUSTOM_CLASS} ]] && return
  # If a copy of the cls file exists locally, use that one
  [[ -f "$(basename "${CUSTOM_CLASS}")" ]] && classfile="$(basename "${CUSTOM_CLASS}")" || classfile=${CUSTOM_CLASS}
  for TEX in "${TEXFILES[@]}"; do
    if grep '\\documentclass' "${TEX}" | grep -q "$(basename "${classfile}" | sed 's/\.cls//g')"; then
      echo "${LIME_YELLOW}Concatenating $(basename "${classfile}") into ${TEX} for portability.${RS}"
      mv "${TEX}" "${TEX}.orig"
      printf "\\\begin{filecontents}{%s}\n" "$(basename "${classfile}")" > "${TEX}"
      { cat "${classfile}"; printf "\\\end{filecontents}\n"; cat "${TEX}.orig"; } >> "${TEX}"
      rm "${TEX}.orig"
      [[ "$classfile" != "${CUSTOM_CLASS}" ]] && echo "$classfile" >> .todel
    fi
  done
}

cataux() { # This function should only be called from $TMPDIR
  echo "${BLUE}Looking for aux files to concatenate.${RS}"
  for TEX in "${TEXFILES[@]}"; do
    find . -type f -iname "*.aux" | sed "s|^\./||" | while read -r aux; do
      if grep -Eq ".*?\{\s*${aux%.*}\s*\}.*?" "${TEX}"; then
        echo "${LIME_YELLOW}Concatenating $(basename "${aux}") into ${TEX} files for portability.${RS}"
        mv "${TEX}" "${TEX}.orig"
        printf "\\\begin{filecontents}{%s}\n" "$(basename "${aux}")" > "${TEX}"
        { cat "${aux}"; printf "\\\end{filecontents}\n"; cat "${TEX}.orig"; } >> "${TEX}"
        rm "${TEX}.orig"
        echo "${aux}" >> .todel
      fi
    done
  done
}

flattentex() { # This function should only be called fom $TMPDIR
  echo "${BLUE}Looking for tex files to concatenate.${RS}"
  for TEX in "${TEXFILES[@]}"; do
    echo "${LIME_YELLOW}Flattening \input and \include statements in ${TEX}.${RS}"
    mv "${TEX}" "${TEX}_tmp.tex"
    if [[ -f "${TEX%.*}.bbl" ]]; then
        latexpand --verbose --fatal --expand-usepackage --expand-bbl "${TEX%.*}.bbl" -o "${TEX}" "${TEX}_tmp.tex"
        _result=$?
    else
        latexpand --verbose --fatal --expand-usepackage -o "${TEX}" "${TEX}_tmp.tex"
        _result=$?
    fi
    rm "${TEX}_tmp.tex" 2>/dev/null
    if [[ ${_result} == 0 ]]; then
      echo "${GREEN}${TEX} flattened.${RS}"
    else
      echo "${RED}latespand failed for ${TEX}.${RS}"
      exit_abnormal
    fi
  done
}

flattendirs() { # This function should only be called from $TMPDIR
  for TEX in "${TEXFILES[@]}"; do
    echo "${LIME_YELLOW}Flattening directory structure for ${TEX}.${RS}"
    _gfxpath=$(grep graphicspath "${TEX}"| cut -d '{' -f '2-' | tr -d '{}')
    _gfxpath=${_gfxpath%/}
    if [[ ! -d "${_gfxpath}" ]]; then
      ls
      echo "${RED} Warning: graphicspath \"${_gfxpath}\" not found (could be a case-sensitivity issue!"
    else
      find "$_gfxpath" \
        -depth -type f -exec mv -v "{}" ./ \;
    fi
    sed -i.bak '/\\graphicspath.*/d' "${TEX}"
  done
  find ./ -depth -type d -empty -delete
}



if [ -z "$1" ]; then
  usage
  exit 0
fi

if ! which latexpand; then
  echo "The latexpand command was not found in your path, it should be included with texlive..."
  exit 0
fi
  
ZIP=0
BZ=0
FORCE=0

while getopts ":o:zjf" options; do
  case "${options}" in
    z)
      ZIP=1
      ;;
    j)
      BZ=1
      ;;
    f)
      FORCE=1
      ;;
    o)
      OUTDIR="${OPTARG}"
      ;;
    :)
      echo "${RED}Error: -${OPTARG} requires an argument.${RS}"
      exit_abnormal
      ;;
    *)
      exit_abnormal
      ;;
  esac
done

# Convert OUTDIR to absolute path
# shellcheck disable=SC2164
OUTDIR=$(cd "${OUTDIR}"; pwd)
if [[ ! -d "$OUTDIR" ]]; then
  echo "${RED}${OUTDIR} is not a directory!${RS}"
  exit_abnormal
fi

if [[ $ZIP == 0 && $BZ == 0 ]]; then
  echo "${RED}You must pick at least one archive option, -z / -j.${RS}"
  exit_abnormal
fi


if [[ ! -d "${TMPDIR}" ]]; then 
  if ! mkdir "${TMPDIR}"; then
    echo "Error creating ${TMPDIR} exiting."
    exit_abnormal
  fi
fi

TEXFILES=()

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for TEX in "$@"
do
  if [[ -d "${TEX}" ]]; then
    if [[ "$OUTDIR" != $(cd "$TEX"; pwd) ]]; then
      echo "${YELLOW}Skipping directory ${TEX}${RS}"
    fi
    continue
  fi
  
  if echo "${TEX}" | grep -q \.tex && [[ -f "${TEX}" ]]; then
    echo "${YELLOW}Parsing ${TEX}${RS}."
    TEXFILES+=("${TEX}")
    echo "Finding deps for ${TEX}"
    finddeps "${TEX}" | xargs -n 1 -I % rsync -q --relative % "${TMPDIR}"
    BIB=$(grep '\\bibliography' "${TEX}" | cut -d '{' -f 2 | sed 's+}+.bib+')
    if [[ -f "$BIB" ]] ; then
      echo "${POWDER_BLUE}Adding ${BIB}${RS}"
      cp "${BIB}" "${TMPDIR}"
    fi
  elif [[ -f "${TEX}" ]]; then
    cp "${TEX}" "${TMPDIR}"
  else
      echo "Not sure what to do with ${TEX}."
  fi
done
IFS=$SAVEIFS

if [[ ${#TEXFILES[@]} == 0 ]]; then
  echo "${RED}No tex files to parse.${RS}"
  exit 0
fi

if cd "${TMPDIR}"
then
  flattentex # Fold all \include and \input statements
  cataux # Cat any aux files required to render the tex file for portability
  catclass  # Cat the custom class file into the tex file for portability
  #echo "${LIME_YELLOW}Removing comments from *.tex${RS}"
  #printf '%s\0' *.tex | xargs -0 -n 1 sed -i.bak '/^%.*$/d'
  flattendirs # Get rid of graphicspath and flatten directory structure
  checktex # Make sure the cleaned tex files are OK
  texok=$?
  [[ $FORCE == 1 ]] && texok=0
  # Get deps from concatenated tex file
  for TEX in "${TEXFILES[@]}"; do
    finddeps "${TEX}" | sed 's+\./++g' >> .tozip
  done
  # Cleanup files that were concatenated
  while read -r todel; do
    echo "${BLUE}Cleaning up $todel."
    rm "$todel"
    sed -i.bak "/${todel}/d" .tozip
  done < <(cat .todel)
  sed -i.bak '/.*\.out/d' .tozip
  rm ./*.out ./*.bak .todel 2>/dev/null
  
  if [[ $ZIP == 1 ]] && [[ $texok == 0 ]]; then
    echo "${POWDER_BLUE}Compressing files to ${OUTDIR}/${BASENAME}.zip${RS}"
    # .tozip has one file per line and sed quotes them already
    # shellcheck disable=SC2046
    zip -r9 "${OUTDIR}/${BASENAME}.zip" $(uniq .tozip | sed 's+\(.*?\)+"\1"+g') *.bib 2>/dev/null
  fi
  if [[ $BZ == 1 ]] && [[ $texok == 0 ]]; then
    echo "${POWDER_BLUE}Compressing files to ${OUTDIR}/${BASENAME}.tar.bz2${RS}"
    # .tozip has one file per line and sed quotes them already
    # shellcheck disable=SC2046
    tar -cjvf "${OUTDIR}/${BASENAME}.tar.bz2" $(uniq .tozip | sed 's+\(.*?\)+"\1"+g') *.bib
  fi
  rm .tozip 2>/dev/null
  cd ..
  rm -fr "${TMPDIR}"
else
  echo "${RED}Error enterting temp dir ${TMPDIR}${RS}"
  exit_abnormal
fi
