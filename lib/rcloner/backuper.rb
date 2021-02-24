require 'uri'
require 'dotenv/load'
require 'pathname'

module Rcloner
  class Backuper
    class ConfigError < StandardError; end

    def initialize(config)
      @config = config

      @config['origin'] ||= ENV['RCLONER_ORIGIN'] || ENV['PWD']
      @config['destination'] ||= ENV['RCLONER_DESTINATION']

      # Provide absolute paths for files in include list
      if @config['include']
        @config['include'] = @config['include'].map { |path| full_local_path(path) }
      end

      # If no entry provided for exclude list and include list exists,
      # that probably means we should only backup these derectories,
      # and skip all the rest - so for that we should provide '**' operator:
      unless @config['exclude']
        @config['exclude'] = ['**']
      end

      # Create tmp/ folder inside root_path:
      Dir.chdir(@config['origin']) do
        FileUtils.mkdir_p(File.join @config['origin'], 'tmp')
      end

      validate_config!
    end

    def backup!
      if before_command = @config.dig('on_backup', 'before')
        puts "Perform before command: #{before_command}"

        Dir.chdir(@config['origin']) do
          execute before_command
        end
      end

      @command = %W(duplicity)
      @config['include'].each { |i| @command.push('--include', i) }
      @config['exclude'].each { |i| @command.push('--exclude', i) }

      @command.push(@config['origin'], @config['destination'])
      execute @command

      if after_command = @config.dig('on_backup', 'after')
        puts "Perform after command: #{after_command}"

        Dir.chdir(@config['origin']) do
          execute after_command
        end
      end
    end

    def restore!(to = nil, force = false)
      @command = %W(duplicity)

      if to
        to = File.expand_path(to)
      else
        to = @config['origin']
      end

      @command.push('restore', @config['destination'], to)
      @command.push('--force') if force
      execute @command
    end

    private

    ###

    def execute(command, env: {}, path: nil)
      if ENV['VERBOSE'] == 'true'
        print_command =
          if command.class == Array
            command.join(' ')
          else
            command
          end

        puts "Execute: `#{print_command}`\n\n"
      end

      if path
        system env, *command, chdir: path
      else
        system env, *command
      end
    end

    ###

    def full_local_path(relative_path)
      File.join(@config['origin'], relative_path)
    end

    # def create_symlink!(from_path, to_path)
    #   if execute %W(ln -s #{from_path} #{to_path})
    #     puts "Created symlink `#{from_path}` -> `#{to_path}`"
    #   end
    # end

    ###

    def validate_config!
      if ENV['PASSPHRASE'].nil? || ENV['PASSPHRASE'].empty?
        raise ConfigError, '`PASSPHRASE` env variable is not set'
      end

      unless @config['destination']
        raise ConfigError, 'Please provide a destination option'
      end
    end
  end
end
