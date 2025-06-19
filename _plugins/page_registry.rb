require 'set'

module Jekyll
  # A central registry to track generated pages across multiple plugins
  # This helps prevent conflicts where multiple plugins try to generate the same page
  class PageRegistry
    # Singleton instance
    @@instance = nil
    
    # Get the singleton instance
    def self.instance
      @@instance ||= new
      @@instance
    end
    
    # Initialize with empty registry
    def initialize
      @registry = Set.new
      @registered_plugins = []
    end
    
    # Register a plugin to use the registry
    def register_plugin(plugin_name)
      puts "PageRegistry: Registered plugin '#{plugin_name}'"
      @registered_plugins << plugin_name unless @registered_plugins.include?(plugin_name)
    end
    
    # Check if a path is already registered
    def registered?(path)
      @registry.include?(path)
    end
    
    # Register a path
    def register(path, plugin_name = nil)
      if registered?(path)
        puts "PageRegistry: Path '#{path}' is already registered"
        return false
      else
        @registry.add(path)
        puts "PageRegistry: Registered path '#{path}'" if plugin_name
        return true
      end
    end
    
    # Reset the registry
    def reset
      @registry.clear
      puts "PageRegistry: Registry cleared"
    end
    
    # Get the number of registered paths
    def count
      @registry.size
    end
    
    # List all registered paths (for debugging)
    def list_paths
      @registry.to_a
    end
  end
  
  # Hook into Jekyll's build process to reset the registry at the start of each build
  Jekyll::Hooks.register :site, :pre_render do |site|
    # Only enable if configured
    if site.config['page_registry']
      PageRegistry.instance.reset
      puts "PageRegistry: Ready for page registration"
    end
  end
end 
