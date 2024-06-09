# modelget Civitai shell script

## 🔍 Overview

This is a small helper script for Civitai Stable Diffusion enthusiasts using Linux.
This scripts can help you quickly download models from Civitai using just your API key and list of links in `.txt` file. Additionaly, it allows using multiple connections to speed up downloading speed. This could be especially useful when you're running some dedicated machines like RunPod where your data is being removed on every session shutdown.

**Pros:**

+ Small one-file script, executed straightly in BASH, no Python and other things needed.
+ Easy to operate, can be used without flags if preferred.
+ Highly portable (probably can even run on Mac with some minor tweaks).
+ Concurrent downloads support -> ca. 2.5x speed compared to browser download.

**Cons:**

- Go ahead and find one (⌐■_■)

## 🛠️ Prerequisites

Just be sure that your Linux machine has `curl` and `aria2` installed, that's all you need.

If something is missing, install it using your favorite package manager or build it yourself.

## 😺 How 2 Use

First of all, clone this repo and open `olinks.txt` file or create your own file.
Write down Civitai links there, one link per line. Example:

```
https://civitai.com/api/download/models/123456
https://civitai.com/api/download/models/654321
*more links here*
```

Make this script runnable by typing in your console:
`chmod +x modelget.sh`.

### 😺 Simplified usage

If you want your download flow to be as simple as possible, additionally open `token.txt` file and write down your token.

After that, just type `./modelget.sh` and it will begin downloading files in your current directory. Token will be retrieved from `token.txt` and list of downloads -- from `olinks.txt`


### 😎 Pro usage with args

Available flags:

```
-i </path/to/txt/file> # Allows to specify input txt file with links
-o </path/to/save/dir> # Allows to specify dir where to store downloads
-x <1-many> # Specify number of concurrent connections. 4-16 recommended.
-j <1-many> # Specify number of parallel files download (from list). 2-4 recommended
-t <token> # You can provide token as an flag
```

Just run the script with them, for example:

`./modelget.sh -i "my_links.txt" -o ~/Download/my_collection/ -x 4 -j 2 -t abeb`
