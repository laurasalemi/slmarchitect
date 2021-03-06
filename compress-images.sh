#!/bin/bash

set -e
set -u

pngquant=$(which pngquant)
jpegoptim=$(which jpegoptim)
chronic=$(which chronic)
# imagemagick=$(which imagemagick)

if [[ -z "$pngquant" ]]; then
    echo "Please install pngquant using brew install pngquant";
    exit 1;
fi


if [[ -z "$jpegoptim" ]]; then
    echo "Please install jpegoptim using brew install jpegoptim";
    exit 1;
fi


if [[ -z "$chronic" ]]; then
  echo "Please install chronic using brew install moreutils";
  exit 1;
fi

# if [[ -z "$imagemagick" ]]; then
#  echo "Please install imagemagick using brew install imagemagick";
#  exit 1;
# fi

find images -iname '*.png' | while read img; do
  old_size=$(stat -f %z "$img")
  echo "Processing $img, starting size is $old_size bytes"

  set +e
  chronic pngquant --skip-if-larger --ext=.png --speed=1 --force "$img"
  result=$?
  set -e

  if [[ "$result" == 98 ]]; then
      echo " - File was skipped because it could not be made smaller"
  elif [[ "$result" != 0 ]]; then
      echo " - PNGQuant failed with exit code $result";
      exit ${result};
  else
    new_size=$(stat -f %z "$img")
    savings=$(expr $old_size - $new_size)
    percentage=$(expr 100 \* $savings / $old_size) || /usr/bin/true  # bin/true so that -e does not make the script exit
    echo " - New size is $new_size bytes, savings are $savings bytes (${percentage}%)"
  fi
done


find images -iname '*.jpg' | while read img; do
  # only shrink larger jpegs
  convert "$img" -resize 1600x1600\> "$img"
  jpegoptim --strip-all -v -p --max=80 "$img"
done

