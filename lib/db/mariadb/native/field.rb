# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../native'

require_relative 'types'

require 'date'
require 'json'

module DB
	module MariaDB
		module Native
			Type = ffi_define_enumeration(:field_type, [
				:decimal,
				:tiny,
				:short,
				:long,
				:float,
				:double,
				:null,
				:timestamp,
				:longlong,
				:int24,
				:date,
				:time,
				:datetime,
				:year,
				:newdate,
				:varchar,
				:bit,
				:json, 245,
				:newdecimal,
				:enum,
				:set,
				:tiny_blob,
				:medium_blob,
				:long_blob,
				:blob,
				:var_string,
				:string,
				:geometry,
			])
			
			DEFAULT_TYPES = {
				# Pseudo types:
				primary_key: Types::Integer.new('BIGINT AUTO_INCREMENT PRIMARY KEY'),
				foreign_key: Types::Integer.new('BIGINT'),
				text: Types::Text.new("TEXT"),
				string: Types::Text.new("VARCHAR(255)"),
				
				# Aliases
				smallint: Types::Integer.new("SHORT"),
				integer: Types::Integer.new("INTEGER"),
				bigint: Types::Integer.new("LONG"),
				
				# Native types:
				decimal: Types::Decimal.new,
				boolean: Types::Boolean.new,
				tiny: Types::Integer.new("TINY"),
				short: Types::Integer.new("SHORT"),
				long: Types::Integer.new("LONG"),
				float: Types::Float.new,
				double: Types::Float.new("DOUBLE"),
				timestamp: Types::DateTime.new("TIMESTAMP"),
				date: Types::Date.new,
				datetime: Types::DateTime.new("DATETIME"),
				year: Types::Integer.new("YEAR"),
				newdate: Types::DateTime.new("DATETIME"),
				bit: Types::Integer.new("BIT"),
				json: Types::JSON.new,
				newdecimal: Types::Decimal.new,
				enum: Types::Symbol.new,
				set: Types::Integer.new("SET"),
			}
			
			class Field < FFI::Struct
				layout(
					:name, :string,
					:org_name, :string,
					:table, :string,
					:org_table, :string,
					:db, :string,
					:catalog, :string,
					:def, :string,
					:length, :ulong,
					:max_length, :ulong,
					:name_length, :uint,
					:org_name_length, :uint,
					:table_length, :uint,
					:org_table_length, :uint,
					:db_length, :uint,
					:catalog_length, :uint,
					:def_length, :uint,
					:flags, :uint,
					:decimals, :uint,
					:charsetnr, :uint,
					:type, Type,
					:extension, :pointer,
				)
				
				def boolean?
					self[:length] == 1 && (self[:type] == :tiny || self[:type] == :long)
				end
				
				def name
					self[:name]
				end
				
				def type
					if boolean?
						:boolean
					else
						self[:type]
					end
				end
				
				def inspect
					"\#<#{self.class} name=#{self.name} type=#{self.type} length=#{self[:length]}>"
				end
			end
		end
	end
end
