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

module DB
	module MariaDB
		module Native
			Type = enum(
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
			)
			
			DEFAULT_TYPES = {
				decimal: Types::Decimal,
				tiny: Types::Integer,
				short: Types::Integer,
				long: Types::Integer,
				float: Types::Float,
				double: Types::Float,
				timestamp: Types::DateTime,
				longlong: Types::Integer,
				int24: Types::Integer,
				date: Date,
				datetime: Types::DateTime,
				year: Types::Integer,
				newdate: Types::DateTime,
				bit: Types::Integer,
				json: JSON,
				newdecimal: Types::Decimal,
				enum: Types::Symbol,
				set: Types::Integer,
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
				
				def name
					self[:name]
				end
				
				def type
					self[:type]
				end
			end
		end
	end
end
