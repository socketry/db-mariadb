# DB::MariaDB

A light-weight wrapper for Ruby connecting to MariaDB and MySQL servers.

[![Development Status](https://github.com/socketry/db-mariadb/workflows/Test/badge.svg)](https://github.com/socketry/db-mariadb/actions?workflow=Test)

## Installation

Add this line to your application's Gemfile:

    gem 'db-mariadb'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install db-mariadb

## Usage

### Test Setup

#### Darwin/MacPorts

Start the local server:

    > cd '/opt/local' ; /opt/local/lib/mariadb-10.5/bin/mysqld_safe --user=_mysql --datadir='/opt/local/var/db/mariadb-10.5'

Setup local test permissions:

    > sudo /opt/local/lib/mariadb-10.5/bin/mysql
    
    > CREATE USER 'test'@'localhost' IDENTIFIED BY 'test';
    > GRANT ALL PRIVILEGES ON *.* TO 'test'@'localhost';
    > FLUSH PRIVILEGES;

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
