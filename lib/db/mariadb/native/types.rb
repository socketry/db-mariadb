# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require "json"
require "bigdecimal"

module DB
	module MariaDB
		module Native
			# Provides type converters for translating between MariaDB types and Ruby types.
			module Types
				# A text/string type converter.
				class Text
					# Initialize a text type converter.
					# @parameter name [String] The SQL type name.
					def initialize(name = "TEXT")
						@name = name
					end
					
					# @attribute [String] The SQL type name.
					attr :name
					
					# Parse a string value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [String | Nil] The string value.
					def parse(string)
						string
					end
				end
				
				# An integer type converter.
				class Integer
					# Initialize an integer type converter.
					# @parameter name [String] The SQL type name.
					def initialize(name = "INTEGER")
						@name = name
					end
					
					# @attribute [String] The SQL type name.
					attr :name
					
					# Parse an integer value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [Integer | Nil] The parsed integer.
					def parse(string)
						Integer(string) if string
					end
				end
				
				# A boolean type converter.
				class Boolean
					# Get the SQL type name for boolean.
					# @returns [String] The type name.
					def name
						"BOOLEAN"
					end
					
					# Parse a boolean value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [Boolean | Integer | Nil] The parsed boolean value.
					def parse(string)
						case string
						when "0"
							false
						when "1"
							true
						when nil
							nil
						else
							Integer(string)
						end
					end
				end
				
				# A decimal type converter.
				class Decimal
					# Get the SQL type name for decimal.
					# @returns [String] The type name.
					def name
						"DECIMAL"
					end
					
					# Parse a decimal value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [BigDecimal | Nil] The parsed decimal.
					def parse(string)
						BigDecimal(string) if string
					end
				end
				
				# A floating point type converter.
				class Float
					# Initialize a float type converter.
					# @parameter name [String] The SQL type name.
					def initialize(name = "FLOAT")
						@name = name
					end
					
					# @attribute [String] The SQL type name.
					attr :name
					
					# Parse a float value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [Float | Nil] The parsed float.
					def parse(string)
						Float(string) if string
					end
				end
				
				# A symbol/enum type converter.
				class Symbol
					# Get the SQL type name for enum.
					# @returns [String] The type name.
					def name
						"ENUM"
					end
					
					# Parse a symbol value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [Symbol | Nil] The parsed symbol.
					def parse(string)
						string&.to_sym
					end
				end
				
				# A datetime type converter.
				class DateTime
					# Initialize a datetime type converter.
					# @parameter name [String] The SQL type name.
					def initialize(name = "DATETIME")
						@name = name
					end
					
					# @attribute [String] The SQL type name.
					attr :name
					
					# Parse a datetime value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [Time | Nil] The parsed datetime as a UTC Time object.
					def parse(string)
						if string
							parts = string.split(/[\-\s:]/)
							
							return Time.utc(*parts)
						end
					end
				end
				
				# A date type converter.
				class Date
					# Get the SQL type name for date.
					# @returns [String] The type name.
					def name
						"DATE"
					end
					
					# Parse a date value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [Time | Nil] The parsed date as a UTC Time object.
					def parse(string)
						if string
							parts = string.split(/[\-\s:]/)
							
							return Time.utc(*parts)
						end
					end
				end
				
				# A JSON type converter.
				class JSON
					# Get the SQL type name for JSON.
					# @returns [String] The type name.
					def name
						"JSON"
					end
					
					# Parse a JSON value from the database.
					# @parameter string [String | Nil] The raw string value.
					# @returns [Hash | Array | Nil] The parsed JSON with symbolized keys.
					def parse(string)
						::JSON.parse(string, symbolize_names: true) if string
					end
				end
			end
		end
	end
end
