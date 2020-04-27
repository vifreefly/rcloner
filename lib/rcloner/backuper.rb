require 'yaml'
require 'uri'
require 'dotenv'

module Rcloner
  class Backuper
    def initialize(config_path)
      @config = YAML.load(File.read(config_path))
      @project_folder = @config['name'] + '_backup'
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
      db_url =
        if item['read_db_url_from_env']
          Dir.chdir(@config['root_path']) do
            `bundle exec postgressor print_db_url`.strip
          end
        else
          item['db_url']
        end

      raise 'Cant read pgdatabase item db_url' unless db_url

      db_backup_filename = URI.parse(db_url).path.sub('/', '') + '.dump'
      relative_db_backup_filepath = 'tmp/' + db_backup_filename
      local_db_backup_file_path = File.join(@config['root_path'], relative_db_backup_filepath)
      item = { 'path' => relative_db_backup_filepath }

      case to
      when :remote
        env = { 'DATABASE_URL' => db_url }
        execute %W(bundle exec postgressor dumpdb #{local_db_backup_file_path}), env: env
        sync_file(item, to: :remote)
      when :local
        sync_file(item, to: :local)

        if ENV['RESTORE_PGDATABASE'] == 'true'
          command = %W(bundle exec postgressor restoredb #{local_db_backup_file_path})
          command << '--switch_to_superuser' if ENV['SWITCH_TO_SUPERUSER'] == 'true'

          execute command, { 'DATABASE_URL' => db_url }
        end
      end
    end

    def sync_file(item, to:)
      local_file_path = File.join(@config['root_path'], item['path'])
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
    end

    def sync_folder(item, to:)
      local_folder_path = File.join(@config['root_path'], item['path'])
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
      execute %W(rclone sync #{from_path} #{to_path})

      puts "Synced folder `#{folder_name}` from `#{from_path}` to `#{to_path}`"
    end

    ###

    def execute(command, env: {}, path: nil)
      if path
        system env, *command, chdir: path
      else
        system env, *command
      end
    end
  end
end
