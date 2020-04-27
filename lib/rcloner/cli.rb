require 'thor'
require_relative 'backuper'

module Rcloner
  class CLI < Thor
    map %w[--version -v] => :__print_version

    desc '--version, -v', 'Print the version'
    def __print_version
      puts VERSION
    end

    desc 'backup', 'Backup all items to a remote storage'
    def backup
      backuper = create_backuper
      backuper.backup!
    end

    desc 'restore', 'Restore all items from a remote storage'
    def restore
      backuper = create_backuper
      backuper.restore!
    end

    private

    def create_backuper
      config_path = './rcloner.yml'
      raise 'Please provide a config path' unless config_path

      Backuper.new(config_path)
    end
  end
end
