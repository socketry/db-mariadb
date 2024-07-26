# Getting Started

This guide explains how to get started with the `db-mariadb` gem.

This gem provides an adapter for the `db` gem. You should consult the [`db` gem documentation](https://socketry.github.io/db/) for general usage.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add db-mariadb
~~~

## Usage

Here is an example of the basic usage of the adapter:

~~~ ruby
require 'async'
require 'db/mariadb'

# Create an event loop:
Sync do
	# Create the adapter and connect to the database:
	adapter = DB::MariaDB::Adapter.new(database: 'test')
	connection = adapter.call
	
	# Execute the query:
	result = connection.send_query("SELECT VERSION()")
	
	# Get the results:
	pp connection.next_result.to_a
	# => [["10.4.13-MariaDB"]]
ensure
	# Return the connection to the client connection pool:
	connection.close
end
~~~
