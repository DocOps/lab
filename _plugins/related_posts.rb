# frozen_string_literal: true

# Jekyll plugin that adds a `related_posts` drop to every document
#  in the `blog` collection.
# The drop returns an array of Hashes.

module Jekyll
  # Drop that knows how to compute related posts for a given page.
  class RelatedPostsDrop < Liquid::Drop
    def initialize page, site
      super()
      @page = page
      @site = site
    end

    # Returns Array<Hash> of related posts, where each Hash has the form:
    #   { "post" => <Document>, "match_count" => Integer, "common_tags" => Array<String> }
    # Sorted descending by `match_count`.
    def related_posts
      return [] unless @page.data['tags'].is_a?(Array) && !@page.data['tags'].empty?

      page_tags = @page.data['tags'].to_set(&:downcase)
      related_append = @page.data['related-posts-append']

      collection = @site.collections['blog']
      return [] unless collection

      matches = collection.docs.map do |doc|
        next if doc.id == @page.id

        # skip posts marked for removal
        next if @page.data['related-posts-remove']&.include?(doc.data['slug'])

        # Ensure the candidate also has tags.
        next unless doc.data['tags'].is_a?(Array)

        # Count intersecting tags.
        common = doc.data['tags']
                    .to_set(&:downcase)
                    .intersection(page_tags)

        # don't add unless there are at least 2 commonalities
        if common.size > 1
          { 'post' => doc, 'match_count' => common.size, 'common_tags' => common.to_a }
        elsif related_append&.include?(doc.data['slug'])
          { 'post' => doc, 'match_count' => 0, 'common_tags' => ['appended'] }
        end
      end.compact

      # Sort most‑similar first.
      matches.sort_by { |h| -h['match_count'] }
    end
  end

  # Generator that attaches the drop to every document in the collection.
  class RelatedPostsGenerator < Generator
    safe true
    priority :low

    def generate site
      collection = site.collections['blog']
      return unless collection

      collection.docs.each do |doc|
        # `doc.data` is the front‑matter hash for the page.
        doc.data['related_posts'] = RelatedPostsDrop.new(doc, site)
      end
    end
  end
end
