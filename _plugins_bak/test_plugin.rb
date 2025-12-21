module Jekyll
  class TestPlugin < Generator
    safe true

    def generate(site)
      puts "=== TestPlugin is running! ==="
      puts "Site source: #{site.source}"
      puts "Site destination: #{site.dest}"
      puts "Safe mode: #{site.safe}"
      puts "=== TestPlugin finished ==="
    end
  end
end 