require 'yaml'
require 'fileutils'

def create_index(path, title, lang, data_folder)
  dir = File.dirname(path)
  FileUtils.mkdir_p(dir)
  
  content = <<~EOF
  ---
  title: #{title}
  lang: #{lang}
  description: Explore resources related to #{title}
  data_folder: #{data_folder}
  show_discussion: true
  ---
  EOF
  
  # Only create if it doesn't exist to avoid overwriting custom changes (like Academics)
  unless File.exist?(path)
    File.write(path, content)
    puts "Created #{path}"
  else
    puts "Skipped #{path} (exists)"
  end
end

langs = ['en-US', 'pt-BR']
root = "/home/nakamoto/dev/z-opensource/IPLibrary-website"

langs.each do |lang|
  menu_file = File.join(root, "_data", lang, "menu.yaml")
  menu = YAML.load_file(menu_file)
  
  menu.each do |item|
    # Skip items explicitly marked? No, assume all top-level need index
    next unless item['path']
    
    # Construct physical path from URL path
    # item['path'] e.g. /en-US/computing/ -> en-US/computing/index.md
    rel_path = item['path'].sub(/^\//, '') # remove leading slash
    file_path = File.join(root, rel_path, "index.md")
    
    title = item['title']
    data_folder = item['data_folder']
    
    if data_folder
       create_index(file_path, title, lang, data_folder)
    end
  end
end
