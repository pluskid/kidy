require 'erb'
require 'yaml'

# Monkey patch Hash to add a method missing for easy access
# like hash.name instead of hash['name'].
class Hash
  def method_missing(method, *args)
    key = method.to_s
    case key
    when /=$/
      self[key] = args.first
    else
      self[key]
    end
  end
end

module InstructionSetGenerator
  def self.generate(template, output=nil)
    self.load_instructions
    template = template.read if template.kind_of? File
    result = ERB.new(template).result(binding)
    if output
      output = File.open(output, "w") unless output.kind_of? File
      output.write(result)
    end
    result
  end

  def self.load_instructions
    if @instructions.nil?
      @instructions = YAML.load(File.open(File.dirname(__FILE__) + '/iset.yml'))
    end
  end
end
