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
    # filter_info
  end

  def filter_info
    @info.select! { |i| !i.end_with?('(does not exist)')}
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

  def local_metadata_versions
    Dir.entries(File.join(@dir, '.metadata')).reject { |i| DIR_BLACKLIST.include?(i) }.sort
  end

  def deprecated?
    @deprecated ||= @name.include?('(!)')
  end

  def can_cleanup?
    (local_versions.length > 1 || local_metadata_versions.length > 1) || @deprecated
  end

  def outdated?
    current_version != installed_version
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

  def old_metadata
    _, *previous = local_metadata_versions.reverse
    previous
  end

  def cleanup
    return unless can_cleanup?
    if @deprecated == true
      yield self, local_versions
      rm_cask
    else
      yield self, old_versions
      rm_old(old_versions, method(:rm_version))
      rm_old(old_metadata, method(:rm_metadata))
    end
  end

  def rm_old(versions, method)
    versions.each do |version|
      method.call(version)
    end
  end

  def rm_version(version)
    dir = File.join(@dir, version)
    ::FileUtils.rm_rf(dir, secure: true, verbose: true)
  end

  def rm_metadata(version)
    dir = File.join(@dir, '.metadata', version)
    ::FileUtils.rm_rf(dir, secure: true, verbose: true)
  end

  def rm_cask
    ::FileUtils.rm_rf(@dir, secure: true, verbose: true)
  end
end
