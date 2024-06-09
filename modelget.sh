#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
REDBOLD="\e[01;31m"
YELLOWBOLD="\e[01;33m"
GREENBOLD="\e[01;32m"


while getopts i:d:x:j:t: flag
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
    echo "${token}"
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
    # First connection without following redirects to check whether the token is supported
    try_errcode=$(curl "${url}" --max-time 5 -s -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" | grep -ho "Unauthorized")
    # echo "${try_errcode}"

    if [ -z ${try_errcode} ]
    then
      # If no "Unauthorized" error was returned, continue retrieving final URL (follow all redirects)
      furl=$(curl "${url}" --max-time 5 -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -s -L -I -o /dev/null -w '%{url_effective}')
      # Debugging purposes
      # echo ${furl}
    else
      furl=""
    fi
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
    echo ${furl} >> flinks.txt
  else
    echo -e "${REDBOLD}URL is NOT resolved, ignoring...\nIt is a good idea to check your token!${ENDCOLOR}"
  fi
done < ${infile}

echo -e "${GREENBOLD}Done resolving redirects!${ENDCOLOR}"


aria2c -i flinks.txt --dir=${outdir} -j ${conjobs} -x ${conconn}

# Delete temporary file with resolved links
rm flinks.txt

echo -e "${GREENBOLD}Modelget out. Happy stable diffusing ( • ᴗ - ) ✧.${ENDCOLOR}"
