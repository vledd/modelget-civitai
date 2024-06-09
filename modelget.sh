#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
REDBOLD="\e[01;31m"
YELLOWBOLD="\e[01;33m"
GREENBOLD="\e[01;32m"


while getopts i:o:d:x:j:t: flag
do
  case "${flag}" in
    i) infile=${OPTARG};; # specify txt file with links
    o) outdir=${OPTARG};; # specify models download folder
    x) conconn=${OPTARG};; # number of concurrent connections (4 recommended)
    j) conjobs=${OPTARG};; # number of concurrent files being downloaded (from txt file)
    t) token=${OPTARG};; # Civitai token
  esac
done


# --------------- CHECK IF LINKS FILE IS CORRECT ---------------
if [ -z ${infile} ]
then
  echo -e "${YELLOWBOLD}No links file provided! Use -i flag to specify.\nNow searching for \"olinks.txt\"${ENDCOLOR}"
  infile=olinks.txt
fi

if [ -f ${infile} ]
then
  echo -e "${GREEN}Found links file...${ENDCOLOR}"
else
  echo -e "${REDBOLD}No links file found. Searched for \"${infile}\"\nAborting...${ENDCOLOR}"
  exit
fi
# --------------- END ---------------

# --------------- CHECK OUTPUT DIR ---------------
if [ -z ${outdir} ]
then
  echo -e "${YELLOWBOLD}No output dir provided, defaulting in current directory${ENDCOLOR}"
  outdir="./"
fi
# --------------- END ---------------

# --------------- CHECK TOKEN ---------------
if [ -z ${token} ]
then
  echo -e "${YELLOWBOLD}No token provided, trying to retrieve from \"token.txt\"${ENDCOLOR}"
  if [ -f "token.txt" ]
  then
    read -r token < "token.txt"
    # echo "${token}"
  else
    echo -e "${REDBOLD}No token.txt file found.\nAborting...${ENDCOLOR}"
    exit
  fi
fi
# --------------- END ---------------

# --------------- CHECK JOBS ---------------
if [ -z ${conjobs} ]
then
  conjobs=2
fi
# --------------- END ---------------

# --------------- CHECK CONCURRENT CONNS ---------------
if [ -z ${conconn} ]
then
  conconn=6
fi
# --------------- END ---------------


function get_final_url {
    # Since user should pass links to a page, we additionally need to parse it for download link. We search for "/api/download/models/" button element
    _download_url=$(curl -s "${url}" | grep -ho "/api/download/models/[^\"]*" | head -1 | awk '{print "https://civitai.com"$1}')
    # echo ${_download_url}

    # First connection without following redirects to check whether the token is supported
    try_errcode=$(curl "${_download_url}" --max-time 5 -s -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" | grep -ho "Unauthorized")
    # echo "${try_errcode}"

    if [ -z ${try_errcode} ]
    then
      # If no "Unauthorized" error was returned, continue retrieving final URL (follow all redirects)
      furl=$(curl "${_download_url}" --max-time 5 -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -s -L -I -o /dev/null -w '%{url_effective}')
      # Debugging purposes
      # echo ${furl}
    else
      furl=""
    fi
}

function get_preview_img {
  # Find first image on the page and use it as a preview
  _img_addr=$(curl -s ${url} | grep -ho "https://image.civitai.com/[^\"]*" | head -1)
  # Retrieve file name from url since Civitai and cURL are bad friends, Civitai returns "forbidden" error when commenting
  _img_name=$(curl -s ${_download_url} -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -LIs | grep -ho "filename%3D%22[^.]*" | cut -c15- | awk '{print $1".preview.png"}')
  # echo ${_img_addr}
}

# Force bash to create a new file or erase its contents
# This is needed because aria2 is not very clever and pushes headers into every redirect.
# This results in an Auth error after the first redirect. So we resolve links with cURL first...
>flinks.txt

while IFS= read -r line
do
  # Add final urls line by line
  echo "Resolving final URL for: $line ..."
  url=${line}

  get_final_url 
  if [ -z ${try_errcode} ]
  then
    echo -e "${GREEN}URL is resolved${ENDCOLOR}"
    # Now download file and preview image
    get_preview_img
    echo ${furl} >> flinks.txt
    echo "${_img_addr}" >> flinks.txt
    echo "  out=${_img_name}" >> flinks.txt
  else
    echo -e "${REDBOLD}URL is NOT resolved, ignoring...\nIt is a good idea to check your token!${ENDCOLOR}"
  fi
done < ${infile}

echo -e "${GREENBOLD}Done resolving redirects!${ENDCOLOR}"


aria2c -i flinks.txt --dir=${outdir} -j ${conjobs} -x ${conconn}

# Delete temporary file with resolved links
rm flinks.txt

echo -e "${GREENBOLD}Modelget out. Happy stable diffusing ( • ᴗ - ) ✧.${ENDCOLOR}"
