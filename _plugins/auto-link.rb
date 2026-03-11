require "digest"
require "nokogiri"
require "addressable/uri"

module Jekyll
  module CustomPlugin
    class FindFile
      @@find_file_cache = {}
      def self.process(site, link)
        return @@find_file_cache[link] if @@find_file_cache.key(link)
        link_uri = Addressable::URI.parse(link)
        if link_uri&.path
          relative_path = link_uri.path[1..].strip
          relative_path_with_leading_slash = Jekyll::PathManager.join("", relative_path)
          site.each_site_file do |file|
            if [relative_path, relative_path_with_leading_slash].include?(file.url)
              return @@find_file_cache[link] = file
            end
          end
        end
        nil
      end

      def self.ensure_leading_slash(input)
        return input if input.nil? || input.empty? || input.start_with?("/")
        "/#{input}"
      end

      def self.hash_file(path)
        Digest::SHA256.file(path).hexdigest
      end

      def self.hash_text(text)
        Digest::SHA256.hexdigest(text)
      end
    end

    module HashFilter
      def hash_file(link)
        site = @context.registers[:site]
        file = FindFile::process(site, link)
        return nil if file.nil?
        if file.is_a? Jekyll::StaticFile
          FindFile::hash_file(file.path)
        else
          FindFile::hash_text(file.output)
        end
      end
    end

    Liquid::Template.register_filter(HashFilter)

    Jekyll::Hooks.register [:pages, :documents], :post_convert do |doc|
      next unless doc.output_ext == ".html"

      site = doc.site
      relative_url_cache = site.filter_cache[:relative_url] ||= {}
      sanitized_baseurl = site.config["baseurl"].is_a?(String) ? FindFile::ensure_leading_slash(site.config["baseurl"].chomp("/")) : ""
      fragment = Nokogiri::HTML::DocumentFragment.parse(doc.content)
      %w[src href].each do |attribute|
        fragment.css("[#{attribute}^=\"/\"]").each do |item|
          file = FindFile::process(site, item[attribute])
          next if file.nil?

          unless relative_url_cache.key?(file.relative_path)
            relative_path_uri = Addressable::URI.parse(file.relative_path)
            if relative_path_uri&.absolute?
              relative_url_cache[file.relative_path] = file.relative_path
            else
              relative_url_cache[file.relative_path] = FindFile::ensure_leading_slash(file.relative_path).prepend(sanitized_baseurl)
            end
            item[attribute] = relative_url_cache[file.relative_path].dup
          end
        end
      end
      doc.content = fragment.to_html
    end

    Jekyll::Hooks.register :site, :post_render do |site|
      sanitized_baseurl = site.config["baseurl"].is_a?(String) ? FindFile::ensure_leading_slash(site.config["baseurl"].chomp("/")) : ""
      file_hash_map = {}

      site.each_site_file do |file|
        next if file.url.end_with?("/") || file.url.end_with?(".html")
        if file.is_a? Jekyll::StaticFile
          file_hash_map[file.url] = FindFile::hash_file(file.path)
        else
          file_hash_map[file.url] = FindFile::hash_text(file.output)
        end
      end

      (site.pages + site.documents).each do |doc|
        next unless doc.output_ext == ".html"
        fragment = Nokogiri::HTML.parse(doc.output)
        %w[src href].each do |attribute|
          fragment.css("[#{attribute}]").each do |item|
            next unless item[attribute].start_with?(sanitized_baseurl)
            file_url = item[attribute].sub(/^#{Regexp.escape(sanitized_baseurl)}/, "")
            next unless file_hash_map.key?(file_url)
            item[attribute] += "?hash=#{file_hash_map[file_url]}"
          end
        end
        doc.output = fragment.to_html
      end
   end
  end
end
