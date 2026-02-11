# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require_relative "result"
require_relative "../error"

module DB
	module MariaDB
		module Native
			MYSQL_PROTOCOL_TCP = 1
			
			MYSQL_OPT_PROTOCOL = 9
			MYSQL_OPT_NONBLOCK = 6000
			
			MYSQL_WAIT_READ = 1
			MYSQL_WAIT_WRITE = 2
			MYSQL_WAIT_EXCEPT = 4
			MYSQL_WAIT_TIMEOUT = 8
			
			CLIENT_COMPRESS = 0x00000020
			CLIENT_LOCAL_FILES = 0x00000080
			CLIENT_MULTI_STATEMENT = 0x00010000
			CLIENT_MULTI_RESULTS = 0x00020000
			
			ffi_attach_function :mysql_init, [:pointer], :pointer
			ffi_attach_function :mysql_options, [:pointer, :int, :pointer], :int
			ffi_attach_function :mysql_get_socket, [:pointer], :int
			
			ffi_attach_function :mysql_real_connect_start, [:pointer, :pointer, :string, :string, :string, :string, :int, :string, :long], :int
			ffi_attach_function :mysql_real_connect_cont, [:pointer, :pointer, :int], :int
			
			ffi_attach_function :mysql_real_query_start, [:pointer, :pointer, :string, :ulong], :int
			ffi_attach_function :mysql_real_query_cont, [:pointer, :pointer, :int], :int
			
			ffi_attach_function :mysql_use_result, [:pointer], :pointer
			ffi_attach_function :mysql_next_result, [:pointer], :int
			ffi_attach_function :mysql_more_results, [:pointer], :int
			ffi_attach_function :mysql_free_result, [:pointer], :void
			
			ffi_attach_function :mysql_affected_rows, [:pointer], :uint64
			ffi_attach_function :mysql_insert_id, [:pointer], :uint64
			ffi_attach_function :mysql_info, [:pointer], :string
			
			ffi_attach_function :mysql_close, [:pointer], :void
			ffi_attach_function :mysql_errno, [:pointer], :uint
			ffi_attach_function :mysql_error, [:pointer], :string
			
			ffi_attach_function :mysql_stat, [:pointer], :string
			
			ffi_attach_function :mysql_real_escape_string, [:pointer, :pointer, :string, :size_t], :size_t
			
			# A native FFI connection to the MariaDB/MySQL client library.
			class Connection < FFI::Pointer
				# Establish a connection to the MariaDB/MySQL server.
				# @parameter host [String] The hostname or IP address to connect to.
				# @parameter username [String | Nil] The username for authentication.
				# @parameter password [String | Nil] The password for authentication.
				# @parameter database [String | Nil] The database name to connect to.
				# @parameter port [Integer] The port number to connect to.
				# @parameter unix_socket [String | Nil] The Unix socket path for local connections.
				# @parameter client_flags [Integer] Client connection flags.
				# @parameter compression [Boolean] Whether to enable connection compression.
				# @parameter types [Hash] Type mapping configuration.
				# @parameter options [Hash] Additional connection options.
				# @returns [Connection] A new connected instance.
				# @raises [Error] If the connection fails.
				def self.connect(host: "localhost", username: nil, password: nil, database: nil, port: 0, unix_socket: nil, client_flags: 0, compression: false, types: DEFAULT_TYPES, **options)
					pointer = Native.mysql_init(nil)
					Native.mysql_options(pointer, MYSQL_OPT_NONBLOCK, nil)
					
					# if protocol
					# 	Native.mysql_options(pointer, MYSQL_OPT_PROTOCOL, FFI::MemoryPointer.new(:uint, protocol))
					# end
					
					client_flags |= CLIENT_MULTI_STATEMENT | CLIENT_MULTI_RESULTS
					
					if compression
						client_flags |= CLIENT_COMPRESSION
					end
					
					result = FFI::MemoryPointer.new(:pointer)
					
					status = Native.mysql_real_connect_start(result, pointer, host, username, password, database, port, unix_socket, client_flags);
					
					io = ::IO.new(Native.mysql_get_socket(pointer), "r+", autoclose: false)
					
					if status > 0
						while status > 0
							if status & MYSQL_WAIT_READ
								io.wait_readable
							elsif status & MYSQL_WAIT_WRITE
								io.wait_writable
							else
								io.wait_any
							end
							
							status = Native.mysql_real_connect_cont(result, pointer, status)
						end
					end
					
					if result.read_pointer.null?
						raise Error, "Could not connect: #{Native.mysql_error(pointer)}!"
					end
					
					return self.new(pointer, io, types, **options)
				end
				
				# Initialize a native connection wrapper.
				# @parameter address [FFI::Pointer] The pointer to the native connection.
				# @parameter io [IO] The IO object for the socket.
				# @parameter types [Hash] Type mapping configuration.
				# @parameter options [Hash] Additional options.
				def initialize(address, io, types, **options)
					super(address)
					
					@io = io
					@result = nil
					
					@types = types
				end
				
				# @attribute [Hash] The type mapping configuration.
				attr :types
				
				# Wait for the specified IO condition.
				# @parameter status [Integer] The status flags indicating which IO condition to wait for.
				def wait_for(status)
					if status & MYSQL_WAIT_READ
						@io.wait_readable
					elsif status & MYSQL_WAIT_WRITE
						@io.wait_writable
					end
				end
				
				# Check for errors and raise an exception if one occurred.
				# @parameter message [String] The error message prefix.
				# @raises [Error] If an error occurred.
				def check_error!(message)
					if Native.mysql_errno(self) != 0
						raise Error, "#{message}: #{Native.mysql_error(self)}!"
					end
				end
				
				# Get the current connection status.
				# @returns [String] The status string from the server.
				def status
					Native.mysql_stat(self)
				end
				
				# Free the current result set.
				def free_result
					if @result
						Native.mysql_free_result(@result)
						
						@result = nil
					end
				end
				
				# Close the connection and release all resources.
				def close
					self.free_result
					
					Native.mysql_close(self)
					
					@io.close
				end
				
				# Escape a string value for safe inclusion in SQL queries.
				# @parameter value [String] The value to escape.
				# @returns [String] The escaped string.
				def escape(value)
					value = value.to_s
					
					maximum_length = value.bytesize * 2 + 1
					out = FFI::MemoryPointer.new(:char, maximum_length)
					
					Native.mysql_real_escape_string(self, out, value, value.bytesize)
					
					return out.read_string
				end
				
				# Send a query to the server for execution.
				# @parameter statement [String] The SQL statement to execute.
				# @raises [Error] If the query fails.
				def send_query(statement)
					self.free_result
					
					error = FFI::MemoryPointer.new(:int)
					
					status = Native.mysql_real_query_start(error, self, statement, statement.bytesize)
					
					while status != 0
						self.wait_for(status)
						
						status = Native.mysql_real_query_cont(error, self, status)
					end
					
					if error.read_int != 0
						raise Error, "Could not send query: #{Native.mysql_error(self)}!"
					end
				end
				
				# Check if there are more result sets available.
				# @returns [Boolean] True if there are more results.
				def more_results?
					Native.mysql_more_results(self) == 1
				end
				
				# Get the next result set from a multi-result query.
				# @parameter types [Hash] Type mapping to use for this result.
				# @returns [Result | Nil] The next result set, or `nil` if no more results.
				def next_result(types: @types)
					if result = self.get_result
						return Result.new(self, types, result)
					end
				end
				
				# Silently discard any results that the application did not read.
				# @returns [Nil]
				def discard_results
					while result = self.get_result
					end
					
					return nil
				end
				
				# Get the number of rows affected by the last query.
				# @returns [Integer] The number of affected rows.
				def affected_rows
					Native.mysql_affected_rows(self)
				end
				
				# Get the last auto-generated ID from an INSERT query.
				# @returns [Integer] The last insert ID.
				def insert_id
					Native.mysql_insert_id(self)
				end
				
				# Get information about the last query execution.
				# @returns [String | Nil] Information string about the query.
				def info
					Native.mysql_info(self)
				end
				
			protected
				def get_result
					if @result
						self.free_result
						
						# Successful and there are no more results:
						return if Native.mysql_next_result(self) == -1
						
						check_error!("Get result")
					end
					
					@result = Native.mysql_use_result(self)
					
					if @result.null?
						check_error!("Get result")
						
						return nil
					else
						return @result
					end
				end
			end
		end
	end
end
