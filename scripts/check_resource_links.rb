#!/usr/bin/env ruby
# Spec 002: verify that every curated resource URL is reachable (needs network).
# Usage: ruby scripts/check_resource_links.rb [glob]   (default: _data/{en-US,pt-BR}/*/*/*.yaml)
# Exit status 1 when any URL fails; prints one line per failure: file, url, reason.
require 'yaml'
require 'open3'
require 'uri'

ROOT = File.expand_path('..', __dir__)
pattern = ARGV[0] || '_data/{en-US,pt-BR}/*/*/*.yaml'
entries = Dir.glob(File.join(ROOT, pattern)).flat_map do |file|
  list = YAML.safe_load(File.read(file)) || []
  list.select { |entry| entry.is_a?(Hash) && entry['url'] }.map { |entry| [file.delete_prefix("#{ROOT}/"), entry['url']] }
end

# curl handles redirects, HTTP/2 and TLS quirks more reliably than Net::HTTP for this check.
def reachable?(url)
  out, status = Open3.capture2('curl', '-sS', '-o', '/dev/null', '-L', '--max-redirs', '5', '--max-time', '25',
                               '-A', 'Mozilla/5.0 (IPLibrary link check; +https://ipl.better-web.org)', '-H', 'Accept: text/html,*/*',
                               '-w', '%{http_code}', url)
  code = out.to_i
  return [true, code.to_s] if code.between?(200, 399)
  # Sites that block automated clients but exist (verify these by hand)
  return [true, "#{code} (blocked bot, check manually)"] if [401, 403, 429].include?(code)

  [false, status.success? ? code.to_s : "curl exit #{status.exitstatus}"]
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
