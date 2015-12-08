module Emfrp
  class FileLoader
    def initialize(include_dirs)
      @include_dirs = include_dirs
      @loaded_hash = {}
    end

    def loaded?(path)
      @loaded_hash.has_key?(path)
    end

    def loaded_full_path(path)
      raise "assertion error" unless loaded?(path)
      @loaded_hash[path][1]
    end

    def get_src_from_full_path(required_full_path)
      @loaded_hash.each do |path, x|
        src_str, full_path = *x
        if full_path == required_full_path
          return src_str
        end
      end
      raise "#{required_full_path} is not found"
    end

    def add_to_loaded(path, src)
      @loaded_hash[path] = [src, path]
    end

    def load(path)
      path_str = path.is_a?(Array) ? path.join("/") : path
      if path =~ /^\/.*?/ && File.exist?(path)
        src_str = File.open(path, 'r'){|f| f.read}
        return @loaded_hash[path] = [src_str, path]
      end
      @include_dirs.each do |d|
        full_path = File.expand_path(d + path_str)
        if File.exist?(full_path) && File.ftype(full_path) == "file"
          src_str = File.open(full_path, 'r'){|f| f.read}
          return @loaded_hash[path] = [src_str, full_path]
        elsif File.exist?(full_path + ".mfrp") && File.ftype(full_path + ".mfrp") == "file"
          src_str = File.open(full_path + ".mfrp", 'r'){|f| f.read}
          return @loaded_hash[path] = [src_str, full_path + ".mfrp"]
        end
      end
      raise "Cannot load #{path_str}"
    end
  end
end
