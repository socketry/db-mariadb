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

module DB
	module MySQL
		module Native
			attach_function :mysql_fetch_row_start, [:pointer, :pointer], :int
			attach_function :mysql_fetch_row_cont, [:pointer, :pointer, :int], :int
			
			attach_function :mysql_num_rows, [:pointer], :uint64
			attach_function :mysql_num_fields, [:pointer], :uint32
			
			# FieldType = enum(
			# 	:decimal,     Mysql::Field::TYPE_DECIMAL,
			# 	:tiny,        Mysql::Field::TYPE_TINY,
			# 	:short,       Mysql::Field::TYPE_SHORT,
			# 	:long,        Mysql::Field::TYPE_LONG,
			# 	:float,       Mysql::Field::TYPE_FLOAT,
			# 	:double,      Mysql::Field::TYPE_DOUBLE,
			# 	:null,        Mysql::Field::TYPE_NULL,
			# 	:timestamp,   Mysql::Field::TYPE_TIMESTAMP,
			# 	:longlong,    Mysql::Field::TYPE_LONGLONG,
			# 	:int24,       Mysql::Field::TYPE_INT24,
			# 	:date,        Mysql::Field::TYPE_DATE,
			# 	:time,        Mysql::Field::TYPE_TIME,
			# 	:datetime,    Mysql::Field::TYPE_DATETIME,
			# 	:year,        Mysql::Field::TYPE_YEAR,
			# 	:newdate,     Mysql::Field::TYPE_NEWDATE,
			# 	:varchar,     Mysql::Field::TYPE_VARCHAR,
			# 	:bit,         Mysql::Field::TYPE_BIT,
			# 	:newdecimal,  Mysql::Field::TYPE_NEWDECIMAL,
			# 	:enum,        Mysql::Field::TYPE_ENUM,
			# 	:set,         Mysql::Field::TYPE_SET,
			# 	:tiny_blob,   Mysql::Field::TYPE_TINY_BLOB,
			# 	:medium_blob, Mysql::Field::TYPE_MEDIUM_BLOB,
			# 	:long_blob,   Mysql::Field::TYPE_LONG_BLOB,
			# 	:blob,        Mysql::Field::TYPE_BLOB,
			# 	:var_string,  Mysql::Field::TYPE_VAR_STRING,
			# 	:string,      Mysql::Field::TYPE_STRING,
			# 	:geometry,    Mysql::Field::TYPE_GEOMETRY,
			# 	:char,        Mysql::Field::TYPE_CHAR,
			# 	:interval,    Mysql::Field::TYPE_INTERVAL
			# )
			
			FieldType = :uchar
			
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
					:type, FieldType
				)
				
				def name
					self[:name]
				end
			end
			
			attach_function :mysql_fetch_fields, [:pointer], :pointer
			
			class Result < FFI::Pointer
				def initialize(connection, address)
					super(address)
					
					@connection = connection
					@fields = nil
				end
				
				def field_count
					Native.mysql_num_fields(self)
				end
				
				def fields
					unless @fields
						pointer = Native.mysql_fetch_fields(self)
						
						@fields = field_count.times.map do |index|
							Field.new(pointer +  index * Field.size)
						end
					end
					
					return @fields
				end
				
				def field_names
					fields.map(&:name)
				end
				
				def row_count
					Native.mysql_num_rows(self)
				end
				
				alias count row_count
				alias keys field_names
				
				def each
					row = FFI::MemoryPointer.new(:pointer)
					field_count = self.field_count
					
					while true
						status = Native.mysql_fetch_row_start(row, self)
						
						while status != 0
							@connection.wait_for(status)
							
							status = Native.mysql_fetch_row_cont(row, self, status)
						end
						
						pointer = row.read_pointer
						
						if pointer.null?
							break
						else
							yield pointer.get_array_of_string(0, field_count)
						end
					end
					
					@connection.check_error!("Reading recordset")
				end
			end
		end
	end
end
