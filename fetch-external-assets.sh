#!/bin/bash

set -euo pipefail

VENDOR=static/vendor

SHACMD="sha256sum"
SHACMD_CHECK="$SHACMD --strict --check"
if ! command -v sha256sum > /dev/null 2>&1 ; then
  # On macOS, sha256sum is not available. Use `shasum -a 256` instead.
  # But shasum doesn't support --strict and uses --warn instead.
  SHACMD="shasum -a 256"
  SHACMD_CHECK="$SHACMD --warn --check"
fi

function download {
  # Downloads a file from the web and checks that it matches
  # a provided hash. If the comparison fails, exit immediately.
  # Usage: download https://path/to/file /tmp/save-as.tgz ABCEDF12345_THE_HASH
  URL=$1
  DEST=$2
  HASH=$3
  CHECKSUM="$HASH  $DEST"
  rm -f $DEST

  echo $URL...
  curl -# -L -o $DEST $URL
  echo

  if ! echo "$CHECKSUM" | $SHACMD_CHECK > /dev/null; then
    echo "------------------------------------------------------------"
    echo "Download of $URL did not match expected checksum."
    echo "Found:"
    $SHACMD $DEST
    echo
    echo "Expected:"
    echo "$CHECKSUM"
    rm -f $DEST
    exit 1
  fi
}


# Clear any existing vendor resources.
rm -rf $VENDOR

# Create the directory.
mkdir -p $VENDOR

# Fetch resources.

# jQuery (MIT License)
download \
  https://code.jquery.com/jquery-3.4.1.min.js \
  $VENDOR/jquery.js \
  '0925e8ad7bd971391a8b1e98be8e87a6971919eb5b60c196485941c3c1df089a'

# Bootstrap (MIT License)
download \
  https://github.com/twbs/bootstrap/releases/download/v4.6.0/bootstrap-4.6.0-dist.zip \
  /tmp/bootstrap.zip \
  '0a211451ad260ab512a7e5c2a1636cf29949c615876590fe2be5012520eed423'
unzip -d /tmp /tmp/bootstrap.zip
mv /tmp/bootstrap-4.6.0-dist $VENDOR/bootstrap
rm -f /tmp/bootstrap.zip


# d3
download \
  https://cdnjs.cloudflare.com/ajax/libs/d3/3.4.13/d3.min.js \
  $VENDOR/d3.js \
  'f717263df71b14fb151931ad0a9695738fb98124a76bb723e1b9cfb9152b7a3e'

# fonts via Google Fonts
# first download a helper (note: we're about to run a foreign script locally)
# TODO: Requires bash v4 not available on macOS. Also it returns with a non-zero
# exit status ("Failed to determine local font name") but it works, so ignore
# exit status with || true
download \
  https://raw.githubusercontent.com/neverpanic/google-font-download/ba0f7fd6de0933c8e5217fd62d3c1c08578b6ea7/google-font-download \
  /tmp/google-font-download \
  '1f9b2cefcda45d4ee5aac3ff1255770ba193c2aa0775df62a57aa90c27d47db5'
(cd $VENDOR; bash /tmp/google-font-download -f woff,woff2 -o google-fonts.css "Raleway:400" "Raleway:700" "Ubuntu:300" "Source Code Pro:500") || true
rm -f /tmp/google-font-download
# generated with: `$SHACMD $VENDOR/{google-fonts.css,*woff*}` but then put the vendor path variable back
$SHACMD_CHECK << EOF
eab87903fbc0aa2b24afff89ded1faa3df38defeaedeca1da25867566b4535f2  $VENDOR/google-fonts.css
0925e8ad7bd971391a8b1e98be8e87a6971919eb5b60c196485941c3c1df089a  $VENDOR/jquery.js
a02462a6c8721b680a2bc724bb2bd7e65a38c4f845269493b8dcdf015b8c47ba  $VENDOR/Raleway_400.woff
1d94fd1a3793df0abe10fb36e59825864e1ec9623496e1e04c9cca624be01394  $VENDOR/Raleway_400.woff2
5d9d2c02d6ba48a49e9b2939cfc68f6f2b69e23c3cb4b46bf61f4f2125b0305d  $VENDOR/Raleway_700.woff
0d3b3a3f34ffd3526eea2f77aebe34caa8e86c59002dfd89aa834b0986feeaa2  $VENDOR/Raleway_700.woff2
af745335fbee4a56303a8f124c83d703e963e489d1b917e7c015c9c202d91384  $VENDOR/Source_Code_Pro_500.woff
f29cd3a2bdcacf9f9f7285c9b74d89f55634f4d43752d81a48914afa7442eb66  $VENDOR/Source_Code_Pro_500.woff2
ab8a55e7d1488e611ecf9d68f0cc16e4c0fdf9e823ab7ae07712cf4ba1fdac71  $VENDOR/Ubuntu_300.woff
8f22c14d833819460602bd41792732725e48a6a6ee48f768a298cde40e16584f  $VENDOR/Ubuntu_300.woff2
EOF
