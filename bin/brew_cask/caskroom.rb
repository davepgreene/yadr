require_relative './cask'
require 'thor'

class Caskroom < Thor::Shell::Basic
  attr_reader :casklist

  def initialize
    super
    @casks = `brew cask ls`.split("\n")
    @casklist = @casks.map do |cask|
      Cask.new(cask)
    end
  end

  def outdated
    outdated_casks = @casklist.select(&:outdated?)
    output = outdated_casks.map do |cask|
      [cask.name, cask.installed_version, cask.current_version]
    end
    yield output
  end

  def get(cask_name)
    @casklist.select { |e| e.name == cask_name }.first
  end
end
