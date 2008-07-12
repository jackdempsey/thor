require 'thor/error'

class Thor
  module Util
    
    def self.constant_to_thor_path(str, remove_default = true)
      str = snake_case(str.to_s).squeeze(":")
      str.gsub!(/^default/, '') if remove_default
      str
    end

    def self.constant_from_thor_path(str)
      make_constant(to_constant(str))
    rescue NameError => e
      raise e unless e.message =~ /^uninitialized constant (.*)$/
      raise Error, "There was no available namespace `#{str}'."
    end

    def self.to_constant(str)
      str = 'default' if str.empty?
      str.gsub(/:(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    def self.constants_in_contents(str)
      klasses = self.constants.dup
      eval(str)
      ret = self.constants - klasses
      foo = []
      ret.each do |k|
        nested_constants = get_constants_for(k)
        if nested_constants && !nested_constants.empty?
          foo << nested_constants.map {|x| "#{k}::#{x}"}
        end
        self.send(:remove_const, k)
      end
      (ret + foo).flatten
    end

    def self.make_constant(str)
      list = str.split("::").inject(Object) {|obj, x| obj.const_get(x)}
    end
    
    def self.snake_case(str)
      return str.downcase if str =~ /^[A-Z_]+$/
      str.gsub(/\B[A-Z]/, '_\&').squeeze('_') =~ /_*(.*)/
      return $+.downcase
    end  

    def self.get_constants_for(klass)
      # the line below is close to make_constant. However that assumes constants defined in Object
      # so it misses whats eval'ed and subsequently defined inside Thor::Util in constants_in_contents
      klass_constant =  klass.split("::").inject(self) {|obj, x| obj.const_get(x)}

      # line below is needed as sometimes klass_constant would come back as 13 instead of FOO
      return unless klass_constant.is_a? Class

      top_level_constants = klass_constant.constants
      return if top_level_constants.empty?
      ret = []
      top_level_constants.each do |const|
        klass_name = "#{klass}::#{const}"
        if (children = get_constants_for(klass_name) )
          ret << children.map {|child| "#{const}::#{child}"}
        end
      end
      (top_level_constants + ret).flatten
    end

  end
end
