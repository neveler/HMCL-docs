shopt -s globstar

echo "locales:" > build/locales.yml
for config in build/config.*.yml; do
    [ -f "$config" ] || continue
    language="${config#build/config.}"
    language="${language%.yml}"
    echo "  - $language" >> build/locales.yml
done

jbuild_mixed() {
    bundle exec jekyll build --trace --verbose --destination build/mixed --config _config.yml,build/locales.yml,"$@"
}

jbuild_single() {
    bundle exec jekyll build --trace --verbose --destination build/single --config _config.yml,build/locales.yml,"$@"
    rm -rf build/single/assets
    rm -rf build/single/feed.xml
    rm -rf build/single/robots.txt
    rm -rf build/single/sitemap.xml
    cp -r build/single/* build/mixed/
}

echo "=== build mixed version ==="
jbuild_mixed $1

echo "=== build default version ==="
jbuild_single build/default.yml,$1

exclude_target=("_data" "_site" "_includes" "_layouts" "_plugins")

for config in build/config.*.yml; do
    [ -f "$config" ] || continue

    language="${config#build/config.}"
    language="${language%.yml}"

    echo "=== build $language version ==="
    echo "cache_dir: .jekyll-cache/$language" > build/single.yml
    echo "include:" >> build/single.yml
    echo "  - _pages" >> build/single.yml
    echo "  - \"*.$language.*\"" >> build/single.yml
    echo "exclude:" >> build/single.yml
    echo "  - assets/" >> build/single.yml
    echo "  - build/" >> build/single.yml
    echo "  - LICENSE" >> build/single.yml
    echo "  - README.md" >> build/single.yml

    for target in _*; do
        [ -f "$target" ] && continue
        [[ " ${exclude_target[*]} " == *" $target "* ]] && continue

        echo "  - $target/" >> build/single.yml

        find $target -type f -name "*.*" ! -name "*.*.*" | while read -r file; do
            dir="${file%/*}"
            ext="${file##*.}"
            base="${file##*/}"
            name="${base%%.*}"
            dest="$dir/$name.$language.$ext"
            [ -f $dest ] && continue
            cp "$file" "$dest"
        done
    done

    echo "locale: $language" >> build/single.yml
    echo "head_scripts:" >> build/single.yml
    echo "  - /assets/js/theme.$language.js" >> build/single.yml

    jbuild_single build/config.$language.yml,build/single.yml,$1
done

mkdir -p _site
rm -rf _site/*
cp -r build/mixed/* _site/
