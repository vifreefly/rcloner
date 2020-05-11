# Rcloner

> README in progress. Project is on the early stage, use it at your own risk.

Simple wrapper for Rclone (with optional Duplicity backend for Rclone) which allows to sync/restore your application files/database.

## Installation

**1)** [Install](https://rclone.org/install/) **rclone**:

```bash
$ curl https://rclone.org/install.sh | sudo bash
```

**2)** [Install](http://duplicity.nongnu.org/) **duplicity**, minimal supported version is `0.8.09`. If you're using Ubuntu, the most simple way to install latest version is via snap:

```bash
$ sudo snap install duplicity --classic
```

**3)** Install gem **rcloner**:

```bash
$ gem install rcloner
```

Or you can install gem directly from github using [specific_install](https://github.com/rdp/specific_install):

```bash
$ gem install specific_install
$ gem specific_install https://github.com/vifreefly/rcloner
```

Another option is to add gem to your application Gemfile:

```ruby
gem 'rcloner', git: 'https://github.com/vifreefly/rcloner', require: false
```

**4) Install gem postgressor (optional for pgdatabase type)**:

```bash
$ gem install postgressor
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
    duplicity: false
    path: public/images

  - type: file
    path: config/master.key
```

At the moment 3 types of items are supported:

* `file` - sync a single file
* `folder` - sync a directory. For `folder` type there is optional `duplicity` flag. If `duplicity: true`, folder will be synced using duplicity with compression. It's a good option if folder contains a lot of files which syncing each by each will take A LOT of time. Duplicity puts all the files in archive file before copying it to a remote storage.
* `pgdatabase` - sunc application database (postgres only). [Postgressor](https://github.com/vifreefly/postgressor) gem is used under the hood.

### backup

To sync all items from local to remote rclone storage use `backup` command:

```
deploy@server:~/my_app$ rcloner backup --config rcloner.yml

Dumped database my_app_database to /home/deploy/my_app/tmp/my_app_database.dump file.
Synced file `my_app_database.dump` from `/home/deploy/my_app/tmp/my_app_database.dump` to `remote:my_app_backup/my_app_database.dump`

Synced folder `images` from `/home/deploy/my_app/public/images` to `remote:my_app_backup/images`

Synced file `master.key` from `/home/deploy/my_app/config/master.key` to `remote:my_app_backup/master.key`
```

> Note: to backup database, Rcloner use gem [postgressor](https://github.com/vifreefly/postgressor) under the hood.

### restore

To sync all items from remote rclone storage to local server use `restore` command:

```
deploy@server:~/my_app$ rcloner restore --config rcloner.yml

Synced file `my_app_database.dump` from `remote:my_app_backup/my_app_database.dump` to `/home/deploy/my_app/tmp/my_app_database.dump`

Synced folder `images` from `remote:my_app_backup/images` to `/home/deploy/my_app/public/images`

Synced file `master.key` from `remote:my_app_backup/master.key` to `/home/deploy/my_app/config/master.key`
```

### Information about pgdatabase type restore

If you want to automatically restore application database from a synced backup file, you need to provide additional `RESTORE_PGDATABASE=true` env variable.

Also you can provide `SWITCH_TO_SUPERUSER=true` env variable to temporary switch postgres user to superuser while importing a database (sometimes it's required for a successful import). For more info see documentation for https://github.com/vifreefly/postgressor .

Example:

```
deploy@server:~/my_app$ SWITCH_TO_SUPERUSER=true RESTORE_PGDATABASE=true rcloner restore --config rcloner.yml
```

## How to run backup with a cron

Use Whenewer gem.

## Notes

* Rclone/duplicity integration https://github.com/GilGalaad/duplicity-rclone

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
