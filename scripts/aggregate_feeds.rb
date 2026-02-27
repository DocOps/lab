#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'nokogiri'
require 'feedjira'
require 'httparty'
require 'time'
require 'rss'
require 'yaml'

module AggregateFeeds
  OPML_URL   = ENV.fetch('OPML_URL', 'https://docopslab.org/feeds/docs-blogs.opml')
  OUT_JSON   = '_data/combined_posts.json'
  OUT_RSS    = 'feeds/aggregate.xml'
  USER_AGENT = 'DocOps Lab Feed Aggregator (+https://github.com/DocOps/lab)'
  MAX_POSTS  = 50

  def self.run
    puts "Fetching OPML from #{OPML_URL}..."
    opml_body = fetch_opml(OPML_URL)
    feeds = parse_opml(opml_body)
    puts "Found #{feeds.size} feeds in OPML"

    all_entries = feeds.flat_map { |f| fetch_recent_entries(f[:url], f[:title]) }.compact
    puts "Retrieved #{all_entries.size} total entries from feeds"

    # Sort by date and take top MAX_POSTS
    results = all_entries.sort_by { |e| e['published'] || Time.at(0) }.reverse.take(MAX_POSTS)
    puts "Selected #{results.size} most recent entries"

    require 'fileutils'
    FileUtils.mkdir_p('feeds')
    write_yaml(results)
    write_rss(results)
    puts 'Done.'
  rescue StandardError => e
    warn "Aggregation failed: #{e.class} - #{e.message}"
    exit 1
  end

  def self.fetch_opml url
    resp = HTTParty.get(url, headers: { 'User-Agent' => USER_AGENT }, timeout: 15)
    raise "Failed to fetch OPML (HTTP #{resp.code})" unless resp.success?

    resp.body
  end

  def self.parse_opml xml_body
    doc = Nokogiri::XML(xml_body)
    doc.xpath('//outline[@xmlUrl]').map do |node|
      { title: node['title'] || node['text'] || 'Untitled', url: node['xmlUrl'] }
    end
  end

  def self.fetch_recent_entries feed_url, blog_title
    resp = HTTParty.get(feed_url, headers: { 'User-Agent' => USER_AGENT }, timeout: 20)
    return [] unless resp.success?

    feed = Feedjira.parse(resp.body)
    return [] if feed.entries.empty?

    # Get up to 10 most recent entries from each feed
    feed.entries.take(10).map do |entry|
      {
        'blog_title' => blog_title,
        'title'      => entry.title,
        'url'        => entry.url || entry.entry_id,
        'published'  => entry.published || entry.updated,
        'summary'    => entry.summary || entry.content || ''
      }
    end
  rescue StandardError => e
    warn "Could not fetch #{feed_url}: #{e.class} - #{e.message}"
    []
  end

  def self.write_yaml results
    sorted = results.sort_by { |r| r['published'] || Time.at(0) }.reverse
    File.write(OUT_JSON, sorted.to_json)
    puts "Wrote #{sorted.size} entries to #{OUT_JSON}"
  end

  def self.write_rss results
    rss = RSS::Maker.make('2.0') do |maker|
      maker.channel.title       = "Latest #{MAX_POSTS} posts from the DocOps Lab tech docs blog directory"
      maker.channel.link        = "https://docopslab.org/docs-blogs/latest/"
      maker.channel.description = "Aggregated feed of the latest posts from technical writing and documentation blogs"
      maker.channel.language    = 'en'
      maker.channel.lastBuildDate = Time.now.to_s

      results.sort_by { |r| r['published'] || Time.at(0) }.reverse.each do |entry|
        maker.items.new_item do |item|
          item.title             = "[#{entry['blog_title']}] #{entry['title']}"
          item.link              = entry['url']
          item.guid.content      = entry['url']
          item.guid.isPermaLink  = true
          item.pubDate           = entry['published'].rfc822 if entry['published']
          item.description       = entry['summary']
        end
      end
    end

    File.write(OUT_RSS, rss)
    puts "Wrote combined RSS to #{OUT_RSS}"
  end
end

AggregateFeeds.run if $PROGRAM_NAME == __FILE__
