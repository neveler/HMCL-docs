Jekyll::Hooks.register [:site], :pre_render do |site|
  default_locale = site.config["locale"] || "en"
  locales = Array(site.config["locales"] || default_locale)
  locales.unshift(default_locale) unless locales.include?(default_locale)
  return if locales.length == 0

  return if site.data["plugins"].nil?
  i18n_data = site.data["plugins"]["i18n"]
  return unless i18n_data.is_a? Hash
  fallback_data = i18n_data["fallback"]
  return unless fallback_data.is_a? Hash

  docs_map = {}

  (site.pages + site.documents).each do |doc|
    next unless doc.is_a?(Jekyll::Page) or doc.is_a?(Jekyll::Document)
    basename = File.basename(doc.path)
    doc_locale = basename[/\.([^.]+)\.[^.]*$/, 1]
    next unless doc.data["i18n"] == true

    if doc_locale && locales.include?(doc_locale)
      default_doc_path = doc.path.sub(/\.#{Regexp.escape(doc_locale)}(?=\.\w+$)/, "")
    else
      doc_locale = default_locale
      default_doc_path = doc.path
    end
    docs_map[default_doc_path] ||= {}
    docs_map[default_doc_path][doc_locale] = doc
  end

  docs_map.each_value do |docs|
    default_doc = docs[default_locale]
    next unless default_doc

    locales.each do |locale|
      if docs[locale]
        docs[locale].data["locale"] = locale
        docs[locale].data["origin"] = default_doc
        docs[locale].data["translations"] = docs
        unless locale == default_locale
          docs[locale].data["permalink"] = "/#{locale}#{default_doc.url}"
          docs[locale].instance_variable_set(:@url, nil)
        end
      else
        fallback_locale = fallback_data[locale]
        while fallback_locale
          fallback_doc = docs[fallback_locale]
          break if fallback_doc
          fallback_locale = fallback_data[fallback_locale]
        end
        fallback_doc ||= default_doc

        if fallback_doc.is_a?(Jekyll::Page)
          base, dir, name = fallback_doc.instance_variable_get(:@base), fallback_doc.instance_variable_get(:@dir), fallback_doc.instance_variable_get(:@name)
          new_doc = Jekyll::PageWithoutAFile.new(fallback_doc.site, base, dir, name)
          site.pages << new_doc
        else
          path, collection = fallback_doc.instance_variable_get(:@path), fallback_doc.collection
          new_doc = Jekyll::Document.new(path, site: fallback_doc.site, collection: collection)
          collection.docs << new_doc
        end

        new_doc.content = fallback_doc.content
        fallback_doc.data.each { |k, v| new_doc.data[k] = v }
        new_doc.data["permalink"] = "/#{locale}#{fallback_doc.url}"
        new_doc.data["locale"] = locale
      end
    end
  end
end
