# Rcloner

> Note: README in progress

Simple wrapper for Rclone which allows to sync/restore your application files/database.

## Installation

Install rclone: https://rclone.org/install/

Install rcloner:

```bash
$ gem install rcloner # not working at the moment because gem didn't pushed to rubygems yet
```

```ruby
# Gemfile

gem 'rcloner', git: 'https://github.com/vifreefly/rcloner', require: false
```

## Configuration

First you will need to configure your Rclone `remote` storage.

1. Install rclone
2. Configure rclone remote storage (run `$ rclone config`), name it `remote`.

## Usage

Write a config file, example:

```yml
# rcloner.yml

name: my_app
root_path: /home/deploy/my_app
items:
  - type: pgdatabase
    db_url: "postgres://my_app_username:my_app_userpass@localhost/my_app_database"

  - type: folder
    path: public/images

  - type: file
    path: config/master.key
```

At the moment 3 types of items are supported:

* `file` - sync a single file
* `folder` - sync a directory
* `pgdatabase` - sunc application database (postgres only). [Postgressor](https://github.com/vifreefly/postgressor) gem is used under the hood.

### backup

To sync all items from local to remote rclone storage use `backup` command:

```
deploy@server:~/my_app$ bundle exec rcloner backup

Dumped database my_app_database to /home/deploy/my_app/tmp/my_app_database.dump file.
Synced file `my_app_database.dump` from `/home/deploy/my_app/tmp/my_app_database.dump` to `remote:my_app_backup/my_app_database.dump`

Synced folder `images` from `/home/deploy/my_app/public/images` to `remote:my_app_backup/images`

Synced file `master.key` from `/home/deploy/my_app/config/master.key` to `remote:my_app_backup/master.key`
```

> Note: to backup database, Rcloner use gem [postgressor](https://github.com/vifreefly/postgressor) under the hood

### restore

To sync all items from remote rclone storage to local server use `restore` command:

```
deploy@server:~/my_app$ bundle exec rcloner restore
Synced file `my_app_database.dump` from `remote:my_app_backup/my_app_database.dump` to `/home/deploy/my_app/tmp/my_app_database.dump`

Synced folder `images` from `remote:my_app_backup/images` to `/home/deploy/my_app/public/images`

Synced file `master.key` from `remote:my_app_backup/master.key` to `/home/deploy/my_app/config/master.key`
```

If you want to automatically restore application database from a synced backup file, you need to provide additional `RESTORE_PGDATABASE=true` env variable.

Also you can provide `SWITCH_TO_SUPERUSER=true` env variable to temporary switch postgres user to superuser while importing a database (sometimes it's required for a successful import). For more info see documentation for https://github.com/vifreefly/postgressor .

Example:

```
deploy@server:~/my_app$ SWITCH_TO_SUPERUSER=true RESTORE_PGDATABASE=true bundle exec rcloner restore
```

## How to run backup with a cron

Use Whenewer gem.

## TODO

* Allow to provide a custom config file path for backup/restore commands

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
