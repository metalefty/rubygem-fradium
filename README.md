# Fradium - FreeRADIUS User Manager

Fradium comes from **F**ree**RADIU**S **U**ser **M**anager. Quick and easy tool to manage user database of FreeRADIUS.

## License
This software is licensed under the MIT license.

## Installation

    $ gem install fradium

## Usage

### Configuration

First of all, create a confiuration file called `.fradium.yaml` in your home directory and specify information needed to your RADIUS database. You can define multiple configuration sets called *profile*.

Supported databases are MySQL and MariaDB via `mysql2` adapter so far. It should be work with SQLite or PostgreSQL but still experimental.

```
default: # default profile
  adapter: mysql2
  host: radius.mysql.example.com
  username: root
  password:
  database: radius

staging:
  adapter: mysql2
  host: radius.mysql.example.com
  username: root
  password:
  database: radius_staging
```

Profiles can be choose by `--profile` option. Specify like `--profile=targetprofile`. If not specified, profile named `default` will be refered by default.

### Further usage

It would be easy to use. Running `fradium` without any options will show the usage.

```
usage:
  fradium [--profile=profile] subcommand ...

subcommands as follows:
  create <username>                   # create new user with password
  show <username>                     # show password for username
  showall                             # show all users
  showvalid                           # show valid(not expired) users
  showexpired                         # show expired users
  showexpiry                          # show expiry inforrmation
  expire <username>                   # expire the user right now
  unexpire <username>                 # unexpire the user
  setexpire <username> <expiry date>  # set expiry date (date must be parseable by Time#parse)
  modify <username>                   # generate new password for username
  dbconsole                           # enter database console
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/metalefty/fradium.
