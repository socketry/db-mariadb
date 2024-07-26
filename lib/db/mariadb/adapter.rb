# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative 'connection'

module DB
	module MariaDB
		class Adapter
			def initialize(**options)
				@options = options
			end
			
			attr :options
			
			def call
				Connection.new(**@options)
			end
		end
	end
end
