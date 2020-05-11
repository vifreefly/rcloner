require 'uri'
require 'dotenv'
require 'pathname'

module Rcloner
  class Backuper
    class ConfigError < StandardError; end

    def initialize(config)
      @config = config
      @project_folder = @config['name'] + '_backup'

      # Create tmp/ folder inside root_path:
      Dir.chdir(@config['root_path']) do
        FileUtils.mkdir_p(File.join @config['root_path'], 'tmp')
      end

      validate_config!
    end

    def backup!
      sync_items(to: :remote)
    end

    def restore!
      sync_items(to: :local)
    end

    private

    def sync_items(to:)
      @config['items'].each do |item|
        case item['type']
        when 'folder'
          sync_folder(item, to: to)
        when 'file'
          sync_file(item, to: to)
        when 'pgdatabase'
          sync_pgdatabase(item, to: to)
        end
      end
    end

    def sync_pgdatabase(item, to:)
      if database_url = ENV['DATABASE_URL']
        puts 'Env variable `DATABASE_URL` exists, taking db_url value from it'
      end

      db_url = database_url ||
        if item['read_url_from_env']
          read_dir_path = File.join(@config['root_path'], item['read_url_path'].to_s)
          Dir.chdir(read_dir_path) do
            `postgressor print_db_url`.strip
          end
        else
          item['db_url']
        end

      raise 'Cant read pgdatabase item db_url' unless db_url

      db_backup_filename = URI.parse(db_url).path.sub('/', '') + '.dump'
      relative_db_backup_filepath = 'tmp/' + db_backup_filename
      local_db_backup_file_path = File.join(@config['root_path'], relative_db_backup_filepath)
      item = { 'path' => relative_db_backup_filepath }

      env = { 'DATABASE_URL' => db_url }

      case to
      when :remote
        execute %W(postgressor dumpdb #{local_db_backup_file_path}), env: env
        sync_file(item, to: :remote)
      when :local
        sync_file(item, to: :local)

        if ENV['RESTORE_PGDATABASE'] == 'true'
          if ENV['CREATE_PGUSER'] == 'true'
            execute %W(postgressor createuser), env: env
            puts "Created pg user"
          end

          restore_command = %W(postgressor restoredb #{local_db_backup_file_path})
          restore_command << '--switch_to_superuser' if ENV['SWITCH_TO_SUPERUSER'] == 'true'
          execute restore_command, env: env
        end
      end
    end

    def sync_file(item, to:)
      local_file_path = full_local_path(item['path'])
      file_name = Pathname.new(local_file_path).basename.to_s
      remote_file_path = File.join(@project_folder, file_name)

      case to
      when :remote
        to_path = "remote:#{remote_file_path}"
        from_path = local_file_path
      when :local
        to_path = local_file_path
        from_path = "remote:#{remote_file_path}"
      end

      execute %W(rclone copyto #{from_path} #{to_path})
      puts "Synced file `#{file_name}` from `#{from_path}` to `#{to_path}`"

      if to == :local && item['symlink_on_restore_path']
        symlink_full_path = full_local_path(item['symlink_on_restore_path'])
        create_symlink!(local_file_path, symlink_full_path)
      end
    end

    def sync_folder(item, to:)
      local_folder_path = full_local_path(item['path'])
      folder_name = Pathname.new(local_folder_path).basename.to_s
      remote_folder_path = File.join(@project_folder, folder_name)

      case to
      when :remote
        to_path = "remote:#{remote_folder_path}"
        from_path = local_folder_path
      when :local
        to_path = local_folder_path
        from_path = "remote:#{remote_folder_path}"
      end

      execute %W(rclone mkdir #{to_path})

      if item['duplicity']
        case to
        when :remote
          dup_to_path = "rclone://remote:#{remote_folder_path}"
          dup_from_path = local_folder_path
          dup_command = %W(duplicity #{dup_from_path} #{dup_to_path} --asynchronous-upload --progress)
        when :local
          dup_to_path = local_folder_path
          dup_from_path = "rclone://remote:#{remote_folder_path}"
          dup_command = %W(duplicity restore #{dup_from_path} #{dup_to_path} --force --asynchronous-upload --progress)
        end

        puts "Start syncing folder `#{folder_name}` from `#{from_path}` to `#{to_path}` using duplicity backend..."
        execute dup_command
      else
        execute %W(rclone sync #{from_path} #{to_path})
      end

      puts "Synced folder `#{folder_name}` from `#{from_path}` to `#{to_path}`"

      if to == :local && item['symlink_on_restore_path']
        symlink_full_path = full_local_path(item['symlink_on_restore_path'])
        create_symlink!(local_folder_path, symlink_full_path)
      end
    end

    ###

    def execute(command, env: {}, path: nil)
      puts "Execute: `#{command.join(' ')}`\n\n" if ENV['VERBOSE'] == 'true'

      if path
        system env, *command, chdir: path
      else
        system env, *command
      end
    end

    ###

    def full_local_path(relative_path)
      File.join(@config['root_path'], relative_path)
    end

    def create_symlink!(from_path, to_path)
      execute %W(ln -s #{from_path} #{to_path})
      puts "Created symlink `#{from_path}` -> `#{to_path}`"
    end

    ###

    def validate_config!
      if @config['items'].any? { |item| item['duplicity'] }
        if ENV['PASSPHRASE'].nil? || ENV['PASSPHRASE'].empty?
          raise ConfigError, 'One of your items has duplicity backend but `PASSPHRASE` env variable is not set'
        end
      end

      full_paths = @config['items'].map { |item| full_local_path(item['path']) if item['path'] }.compact
      symlinks = full_paths.select { |path| File.symlink?(path) }
      unless symlinks.empty?
        raise ConfigError, "Symlinks for files/folders are not supported, please use actual paths (symlinks: #{symlinks.join(', ')})"
      end
    end
  end
end
