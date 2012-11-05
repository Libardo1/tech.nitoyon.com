# Convertible#read_yaml cache
#
# This plugin caches `Convertible#read_yaml` result on _caches/posts.yml.

module Jekyll
  class Site
    attr_accessor :yaml_cache

    def read
      @yaml_cache = YamlCache.new(self) if @yaml_cache.nil?

      self.read_layouts
      self.read_directories

      @yaml_modified = @yaml_cache.content_modified
      @yaml_cache.save
    end
  end

  module Convertible
    # Read the YAML frontmatter.
    #
    # base - The String path to the dir containing the file.
    # name - The String filename of the file.
    #
    # Returns nothing.
    def read_yaml(base, name)
      source = File.join(base, name)
      self.content = File.read(source)

      begin
        if self.content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
          self.content = $POSTMATCH
          self.yaml_modified, self.data = site.yaml_cache.get(File.join(base, name), $1)
        end
      rescue => e
        puts "YAML Exception reading #{name}: #{e.message}"
        raise e
      end

      self.data ||= {}

      # Update self.modified
      if self.class.public_method_defined?(:modified)
        src_mtime = Time.at(0)
        src_mtime = File::mtime(source) if FileTest.exists?(source)
        dst_path = self.destination(self.site.dest)
        dst_mtime = File::mtime(dst_path) if FileTest.exists?(dst_path)
        self.modified = dst_mtime && src_mtime > dst_mtime
      end
    end
  end

  class YamlCache
    attr_accessor :content_modified

    def initialize(site)
      @site = site
      @cache_path = File.join(@site.source, '_caches/posts.yml')
      @cache = nil
      @file_modified = false
      @content_modified = false
    end
  
    def get(path, yaml)
      self.load if @cache.nil?
      key = path[@site.source.length..-1]

      if self.has_cache?(key, path)
        [false, self.get_content(key)]
      else
        content = YAML.load(yaml)
        puts "parsed yaml #{key}..."
        self.set_content(key, path, content)
      end
    end

    def has_cache?(key, path)
      @cache.has_key?(key) &&
        File.mtime(path) == @cache[key]['modified']
    end

    def get_content(key)
      # deep copy
      Marshal.load(Marshal.dump(@cache[key]['content']))
    end

    def set_content(key, path, content)
      old_content = @cache[key]['content'] if @cache.has_key?(key)

      @file_modified = true
      modified = YAML.dump(old_content) != YAML.dump(content)
      @content_modified |= modified

      @cache[key] = {
        'content' => content,
        'modified' => File.mtime(path)
      }
      puts "yaml set #{modified}"
      [modified, content]
    end

    def load
      @cache = {}
      if FileTest.file?(@cache_path)
        begin
          @cache = YAML.load_file(@cache_path)
          @cache = {} unless @cache
        rescue => e
          puts "YAML Exception reading #{yaml_path}: #{e.message}"
        end
      end
    end

    def save
      if @file_modified
        yaml = YAML.dump(@cache)
        File.open(@cache_path, "w") { |f| f.write(yaml) }
      end
      @file_modified = @content_modified = false
    end
  end
end
