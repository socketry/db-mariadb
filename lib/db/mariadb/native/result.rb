# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require_relative "field"

module DB
	module MariaDB
		module Native
			ffi_attach_function :mysql_fetch_row_start, [:pointer, :pointer], :int
			ffi_attach_function :mysql_fetch_row_cont, [:pointer, :pointer, :int], :int
			
			ffi_attach_function :mysql_num_rows, [:pointer], :uint64
			ffi_attach_function :mysql_num_fields, [:pointer], :uint32
			
			ffi_attach_function :mysql_fetch_fields, [:pointer], :pointer
			
			# A result set from a database query with row iteration and type casting.
			class Result < FFI::Pointer
				# Initialize a new result set wrapper.
				# @parameter connection [Connection] The connection that produced this result.
				# @parameter types [Hash] Type mapping for field conversion.
				# @parameter address [FFI::Pointer] The pointer to the native result.
				def initialize(connection, types = {}, address)
					super(address)
					
					@connection = connection
					@fields = nil
					@types = types
					@casts = nil
				end
				
				# Get the number of fields in this result set.
				# @returns [Integer] The field count.
				def field_count
					Native.mysql_num_fields(self)
				end
				
				# Get the field metadata for this result set.
				# @returns [Array(Field)] The array of field objects.
				def fields
					unless @fields
						pointer = Native.mysql_fetch_fields(self)
						
						@fields = field_count.times.map do |index|
							Field.new(pointer +  index * Field.size)
						end
					end
					
					return @fields
				end
				
				# Get the field names for this result set.
				# @returns [Array(String)] The array of field names.
				def field_names
					fields.map(&:name)
				end
				
				# Get the type converters for each field.
				# @returns [Array] The array of type converter objects.
				def field_types
					fields.map{|field| @types[field.type]}
				end
				
				# Get the number of rows in this result set.
				# In the context of unbuffered queries, this is the number of rows that have been fetched so far.
				# @returns [Integer] The row count.
				def row_count
					Native.mysql_num_rows(self)
				end
				
				alias count row_count
				alias keys field_names
				
				# Cast row values to appropriate Ruby types.
				# @parameter row [Array] The raw row data.
				# @returns [Array] The row with values cast to proper types.
				def cast!(row)
					@casts ||= self.field_types
					
					row.size.times do |index|
						if cast = @casts[index]
							row[index] = cast.parse(row[index])
						end
					end
					
					return row
				end
				
				# Iterate over each row in the result set.
				# @yields {|row| ...} Each row as an array.
				# 	@parameter row [Array] The current row data.
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
				
				# Map over each row in the result set.
				# @yields {|row| ...} Each row as an array.
				# 	@parameter row [Array] The current row data.
				# @returns [Array] The mapped results.
				def map(&block)
					results = []
					
					self.each do |row|
						results << yield(row)
					end
					
					return results
				end
				
				# Convert the entire result set to an array.
				# @returns [Array(Array)] All rows as arrays.
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
