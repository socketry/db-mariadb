# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require 'async/pool/resource'

require_relative 'native/connection'

module DB
	module MariaDB
		# This implements the interface between the underyling native interface interface and "standardised" connection interface.
		class Connection < Async::Pool::Resource
			def initialize(**options)
				@native = Native::Connection.connect(**options)
				
				super()
			end
			
			def close
				@native.close
				
				super
			end
			
			def types
				@native.types
			end
			
			def append_string(value, buffer = String.new)
				buffer << "'" << @native.escape(value) << "'"
				
				return buffer
			end
			
			def append_literal(value, buffer = String.new)
				case value
				when Time, DateTime
					append_string(value.utc.strftime('%Y-%m-%d %H:%M:%S'), buffer)
				when Date
					append_string(value.strftime('%Y-%m-%d'), buffer)
				when Numeric
					buffer << value.to_s
				when TrueClass
					buffer << 'TRUE'
				when FalseClass
					buffer << 'FALSE'
				when nil
					buffer << 'NULL'
				else
					append_string(value, buffer)
				end
				
				return buffer
			end
			
			def append_identifier(value, buffer = String.new)
				case value
				when Array
					first = true
					value.each do |part|
						buffer << '.' unless first
						first = false
						
						buffer << escape_identifier(part)
					end
				else
					buffer << escape_identifier(value)
				end
				
				return buffer
			end
			
			def key_column(name = 'id', primary: true, null: false)
				buffer = String.new
				
				append_identifier(name, buffer)
				
				buffer << " BIGINT"
				
				if primary
					buffer << " AUTO_INCREMENT PRIMARY KEY"
				elsif !null
					buffer << " NOT NULL"
				end
				
				return buffer
			end
			
			def status
				@native.status
			end
			
			def send_query(statement)
				@native.discard_results
				
				@native.send_query(statement)
			end
			
			def next_result
				@native.next_result
			end
			
			protected
			
			def escape_identifier(value)
				"`#{@native.escape(value)}`"
			end
		end
	end
end
