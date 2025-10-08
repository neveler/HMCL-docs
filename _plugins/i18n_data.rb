require "jekyll"

module Jekyll
  class I18nData < Jekyll::Generator
    def translate(hash, locale)
      return hash unless data.is_a?(Hash)
      hash.each do |key, value|
        if hash["#{key}#{locale}"]
          hash[key] = hash["#{key}#{locale}"]
        else
          hash[key] = translate(value, locale)
        end
      end
      hash
    end

    def generate(site)
      site_locale = site.config['locale'] || 'zh'
      default_locale = site.config['default_locale'] || 'zh'
      if site_locale != default_locale
        site.data = translate(site.data, site.config['locale'])
      end
    end
  end
end
