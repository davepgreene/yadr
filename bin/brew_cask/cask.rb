require 'fileutils'
require 'thor'
require 'open3'

CASKROOM = '/usr/local/Caskroom'.freeze
DIR_BLACKLIST = ['.', '..', '.metadata'].freeze

# Cask control class. Implements operations on a single cask.
class Cask < Thor::Shell::Basic
  attr_reader :name, :dir

  def initialize(name)
    super()
    @name = name
    @info = deprecated? ? [] : `brew cask info #{name}`.split("\n")
    @name = @name.delete(' (!)') if deprecated?
    @deprecated = deprecated?
    @dir = File.join(CASKROOM, @name)
  end

  def current_version
    @info[0].sub("#{@name}: ", '')
  end

  def installed_version
    local_versions.last
  end

  def local_versions
    Dir.entries(@dir).reject { |i| DIR_BLACKLIST.include?(i) }.sort
  end

  def deprecated?
    @deprecated ||= @name.include?('(!)')
  end

  def can_cleanup?
    local_versions.length > 1 || @deprecated
  end

  def outdated?
    @info.join("\n").include?('Not installed')
  end

  def upgrade
    if outdated?
      say "Installing #{@name} (#{current_version})", :cyan
      cmd = "brew cask install #{@name} --force"
      Open3.popen2e(cmd) do |_stdin, stdout_err, _wait_thr|
        while line = stdout_err.gets
          puts line
        end
      end
      say "Upgraded #{@name} to version #{current_version}", :green
    end
  end

  def old_versions
    _, *previous = local_versions.reverse
    previous
  end

  def cleanup
    return unless can_cleanup?
    if @deprecated == true
      yield self, local_versions
      rm_cask
    else
      yield self, old_versions
      rm_versions(old_versions)
    end
  end

  def rm_versions(versions)
    versions.each do |version|
      dir = File.join(@dir, version)
      ::FileUtils.rm_rf(dir, secure: true, verbose: true)
    end
  end

  def rm_cask
    ::FileUtils.rm_rf(@dir, secure: true, verbose: true)
  end
end
