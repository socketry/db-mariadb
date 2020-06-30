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

require_relative 'field'

module DB
	module MariaDB
		module Native
			attach_function :mysql_fetch_row_start, [:pointer, :pointer], :int
			attach_function :mysql_fetch_row_cont, [:pointer, :pointer, :int], :int
			
			attach_function :mysql_num_rows, [:pointer], :uint64
			attach_function :mysql_num_fields, [:pointer], :uint32
			
			attach_function :mysql_fetch_fields, [:pointer], :pointer
			
			class Result < FFI::Pointer
				def initialize(connection, types = {}, address)
					super(address)
					
					@connection = connection
					@fields = nil
					@types = types
					@casts = nil
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
				
				def field_types
					fields.map{|field| @types[field.type]}
				end
				
				def row_count
					Native.mysql_num_rows(self)
				end
				
				alias count row_count
				alias keys field_names
				
				def cast!(row)
					@casts ||= self.field_types
					
					row.size.times do |index|
						if cast = @casts[index]
							row[index] = cast.parse(row[index])
						end
					end
					
					return row
				end
				
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
							yield cast!(pointer.get_array_of_string(0, field_count))
						end
					end
					
					@connection.check_error!("Reading recordset")
				end
				
				def to_a
					rows = []
					
					self.each do |row|
						rows << row
					end
					
					return rows
				end
			end
		end
	end
end
