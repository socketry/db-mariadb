# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require_relative "connection"

module DB
	module MariaDB
		# A database adapter for connecting to MariaDB and MySQL servers.
		class Adapter
			# Initialize a new adapter with connection options.
			# @parameter options [Hash] Connection options to be passed to the connection.
			def initialize(**options)
				@options = options
			end
			
			# @attribute [Hash] The connection options.
			attr :options
			
			# Create a new database connection.
			# @returns [Connection] A new connection instance.
			def call
				Connection.new(**@options)
			end
		end
	end
end
