require 'thor'
require 'yaml'
require_relative 'backuper'

module Rcloner
  class CLI < Thor
    map %w[--version -v] => :__print_version

    desc '--version, -v', 'Print the version'
    def __print_version
      puts VERSION
    end

    desc 'backup', 'Backup all items to a remote storage'
    option :config, type: :string, required: true, banner: 'Path to a config file'
    def backup
      backuper = create_backuper
      backuper.backup!
    end

    desc 'restore', 'Restore all items from a remote storage'
    option :config, type: :string, required: true, banner: 'Path to a config file'
    option :force, type: :boolean, default: false, banner: 'Allow to overwrite existing directory'
    def restore(to = nil)
      backuper = create_backuper
      backuper.restore!(to, options['force'])
    end

    private

    def create_backuper
      config_path = options['config']
      unless File.exists?(config_path)
        raise "Config file `#{config_path}` does not exists"
      end

      config = YAML.load(File.read(config_path))
      Backuper.new(config)
    end
  end
end
