#!/usr/bin/env ruby
# Spec 002: verify that every curated resource URL is reachable (needs network).
# Usage: ruby scripts/check_resource_links.rb [glob]   (default: _data/{en-US,pt-BR}/*/*/*.yaml)
# Exit status 1 when any URL fails; prints one line per failure: file, url, reason.
require 'yaml'
require 'net/http'
require 'uri'

ROOT = File.expand_path('..', __dir__)
pattern = ARGV[0] || '_data/{en-US,pt-BR}/*/*/*.yaml'
entries = Dir.glob(File.join(ROOT, pattern)).flat_map do |file|
  list = YAML.safe_load(File.read(file)) || []
  list.select { |entry| entry.is_a?(Hash) && entry['url'] }.map { |entry| [file.delete_prefix("#{ROOT}/"), entry['url']] }
end

def reachable?(url, limit = 5)
  return [false, 'too many redirects'] if limit.zero?

  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 15) do |http|
    request = Net::HTTP::Get.new(uri, 'User-Agent' => 'IPLibrary-link-check/1.0 (+https://ipl.better-web.org)')
    response = http.request(request) { |res| res.read_body { break } }
    case response
    when Net::HTTPSuccess then [true, response.code]
    when Net::HTTPRedirection then reachable?(URI.join(url, response['location']).to_s, limit - 1)
    # Sites that block automated clients but exist (verify these by hand)
    when Net::HTTPForbidden, Net::HTTPTooManyRequests then [true, "#{response.code} (blocked bot, check manually)"]
    else [false, response.code]
    end
  end
rescue StandardError => error
  [false, error.class.name]
end

queue = Queue.new
entries.uniq { |_, url| url }.each { |item| queue << item }
failures = Queue.new
workers = Array.new(12) do
  Thread.new do
    until queue.empty?
      file, url = begin
        queue.pop(true)
      rescue ThreadError
        break
      end
      ok, reason = reachable?(url)
      failures << [file, url, reason] unless ok
    end
  end
end
workers.each(&:join)

failed = []
failed << failures.pop until failures.empty?
failed.sort.each { |file, url, reason| puts "#{file}\t#{url}\t#{reason}" }
puts "checked #{entries.uniq { |_, url| url }.size} URLs, #{failed.size} failed"
exit(failed.empty? ? 0 : 1)
