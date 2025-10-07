shopt -s globstar

exclude_target=("./_build" "./_data", "_data_bak" "./_site" "./_site_temp" "./_includes" "./_layouts")

echo "cp -r _data _data_bak"
cp -r _data _data_bak

bundle exec jekyll build --trace --verbose --destination _site --config _config.yml,"$1"

for config in ./_build/config.*.yml; do
    [ -f "$config" ] || continue

    language="${config#./_build/config.}"
    language="${language%.yml}"
    echo "build $language version"

    echo "rm -rf _data && cp -r _data_bak _data"
    rm -rf _data && cp -r _data_bak _data
    for data in ./_data/**/*."$language".*; do
        [ -f "$data" ] || continue
        dest="${data/.$language./.}"
        echo "mv $data $dest"
        mv "$data" "$dest"
    done

    for target in ./_*; do
        [ -f "$target" ] && continue
        [[ " ${exclude_target[*]} " == *" $target "* ]] && continue

        find $target -type f -name "*.*" ! -name "*.*.*" | while read -r file; do
            dir="${file%/*}"
            ext="${file##*.}"
            base="${file##*/}"
            name="${base%%.*}"
            language_file="$dir/$name.$language.$ext"
            [ -f $language_file ] && continue
            echo "cp $file $dir/$name.$language.$ext"
            cp "$file" "$dir/$name.$language.$ext"
        done
    done

    bundle exec jekyll build --trace --verbose --destination _site_temp --config "_config.yml,_build/config.$language.yml,$1"

    rm -rf ./_site_temp/assets
    rm -rf ./_site_temp/feed.xml
    rm -rf ./_site_temp/robots.txt
    rm -rf ./_site_temp/sitemap.xml
    cp ./_site_temp/* ./site/
done
