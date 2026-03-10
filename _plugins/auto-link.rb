require "digest"
require "nokogiri"
require "addressable/uri"

module Jekyll
  module AutoLinkPlugin
    # @!attribute [r] site
    #   @return [Jekyll::Site]
    # @!attribute [r] sanitized_baseurl
    #   @return [String]
    # @!attribute [r] relative_url_cache
    #   @return [Hash]
    class AutoLink
      attr_reader :site, :sanitized_baseurl, :relative_url_cache

      # @param [Jekyll::Site] site
      # @return [void]
      def initialize(site)
        @site = site
        @relative_url_cache = site.filter_cache[:relative_url] ||= {}
        @sanitized_baseurl = ensure_leading_slash(site.config["baseurl"] || "")
      end

      # @param [String] link
      # @return [String]
      def process(link)
        link_uri = Addressable::URI.parse(link)
        if link_uri&.path
          relative_path = link_uri.path[1..].strip
          relative_path_with_leading_slash = Jekyll::PathManager.join("", relative_path)
          site.each_site_file do |file|
            if [relative_path, relative_path_with_leading_slash].include?(file.relative_path)
              unless relative_url_cache.key?(file.relative_path)
                relative_path_uri = Addressable::URI.parse(file.relative_path)
                if relative_path_uri&.absolute?
                  relative_url_cache[file.relative_path] = file.relative_path
                else
                  relative_url_cache[file.relative_path] = ensure_leading_slash(file.relative_path).prepend(@sanitized_baseurl)
                  if link_uri.path.start_with?("/assets/")
                    return "#{relative_url_cache[file.relative_path]}?hash=#{file_sha256(file.path)}"
                  end
                end
              end
              return relative_url_cache[file.relative_path].dup
            end
          end
        end
        link_uri.to_s
      end

      private

      # @param [String] input
      # @return [String]
      def ensure_leading_slash(input)
        return input if input.nil? || input.empty? || input.start_with?("/")

        "/#{input}"
      end

      # @param [String] path
      # @return [String]
      def file_sha256(path)
        Digest::SHA256.file(path).hexdigest
      end
    end

    Jekyll::Hooks.register [:pages, :documents], :post_convert do |doc|
      next unless doc.output_ext == ".html"

      auto_link = AutoLink.new(doc.site)
      fragment = Nokogiri::HTML::DocumentFragment.parse(doc.content)
      %w[src href].each do |attribute|
        fragment.css("[#{attribute}^=\"/\"],[#{attribute}$=\".md\"],[#{attribute}^=\"/\"][#{attribute}*=\".md#\"]").each do |item|
          item[attribute] = auto_link.process(item[attribute]) if item[attribute]
        end
      end
      doc.content = fragment.to_html
    end
  end
end
