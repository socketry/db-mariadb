# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative 'field'

module DB
	module MariaDB
		module Native
			ffi_attach_function :mysql_fetch_row_start, [:pointer, :pointer], :int
			ffi_attach_function :mysql_fetch_row_cont, [:pointer, :pointer, :int], :int
			
			ffi_attach_function :mysql_num_rows, [:pointer], :uint64
			ffi_attach_function :mysql_num_fields, [:pointer], :uint32
			
			ffi_attach_function :mysql_fetch_fields, [:pointer], :pointer
			
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
				
				# In the context of unbuffered queries, this is the number of rows that have been fetched so far.
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
				
				def map(&block)
					results = []
					
					self.each do |row|
						results << yield(row)
					end
					
					return results
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
