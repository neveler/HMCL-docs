require "digest"
require "addressable/uri"

module HashFileFilter
  def hash_file(link, only_hash = false)
    site = @context.registers[:site]
    link_uri = Addressable::URI.parse(link)
    if link_uri&.path
      relative_path = link_uri.path[1..].strip
      relative_path_with_leading_slash = Jekyll::PathManager.join("", relative_path)
      site.each_site_file do |file|
        if [relative_path, relative_path_with_leading_slash].include?(file.relative_path)
          hash = Digest::SHA256.file(file.path).hexdigest
          return only_hash ? "?hash=#{hash}" : "#{link}?hash=#{hash}"
        end
      end
    end
    only_hash ? nil : link
  end
end

Liquid::Template.register_filter(HashFileFilter)
