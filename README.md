# Rcloner

> Note: README in progress

Simple wrapper for Rclone which allows to sync/restore your application files/database.

## Installation

```bash
$ gem install rcloner # not working at the moment because gem didn't pushed to rubygems yet
```

```ruby
https://github.com/vifreefly/rcloner
```

## Configuration

First you will need to configure your Rclone `remote` storage.

1. Install rclone
2. Configure rclone remote storage, call it `remote`

## Usage

Write a config file, example:

```yml
# rcloner.yml

name: my_app
root_path: /home/deploy/my_app
items:
  - type: pgdatabase
    db_url: "postgres://my_app_username:my_app_userpass@localhost/my_app_database_name"

  - type: folder
    path: public/images

  - type: file
    path: config/master.key
```

To sync all items from local to remote, run:

```bash
$
```


## How to run backup with a cron

Use Whenewer gem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
