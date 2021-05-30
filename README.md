# DB::MariaDB

A light-weight wrapper for Ruby connecting to MariaDB/MariaDB.

[![Development Status](https://github.com/socketry/db-mariadb/workflows/Development/badge.svg)](https://github.com/socketry/db-mariadb/actions?workflow=Development)

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

~~~
> cd '/opt/local' ; /opt/local/lib/mariadb-10.5/bin/mysqld_safe --user=_mysql --datadir='/opt/local/var/db/mariadb-10.5'
~~~

Setup local test permissions:

~~~
> sudo /opt/local/lib/mariadb-10.5/bin/mysql

> CREATE USER 'test'@'localhost' IDENTIFIED BY 'test';
> GRANT ALL PRIVILEGES ON *.* TO 'test'@'localhost';
> FLUSH PRIVILEGES;
~~~

## Contributing

1.  Fork it
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create new Pull Request

## License

Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
