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

require_relative 'result'
require_relative '../error'

module DB
	module MariaDB
		module Native
			MYSQL_OPT_NONBLOCK = 6000
			
			MYSQL_WAIT_READ = 1
			MYSQL_WAIT_WRITE = 2
			MYSQL_WAIT_EXCEPT = 4
			MYSQL_WAIT_TIMEOUT = 8
			
			CLIENT_COMPRESS = 0x00000020
			CLIENT_LOCAL_FILES = 0x00000080
			CLIENT_MULTI_STATEMENT = 0x00010000
			CLIENT_MULTI_RESULTS = 0x00020000
			
			attach_function :mysql_init, [:pointer], :pointer
			attach_function :mysql_options, [:pointer, :int, :pointer], :int
			attach_function :mysql_get_socket, [:pointer], :int
			
			attach_function :mysql_real_connect_start, [:pointer, :pointer, :string, :string, :string, :string, :int, :string, :long], :int
			attach_function :mysql_real_connect_cont, [:pointer, :pointer, :int], :int
			
			attach_function :mysql_real_query_start, [:pointer, :pointer, :string, :ulong], :int
			attach_function :mysql_real_query_cont, [:pointer, :pointer, :int], :int
			
			attach_function :mysql_use_result, [:pointer], :pointer
			attach_function :mysql_next_result, [:pointer], :int
			attach_function :mysql_more_results, [:pointer], :int
			attach_function :mysql_free_result, [:pointer], :void
			
			attach_function :mysql_affected_rows, [:pointer], :uint64
			attach_function :mysql_insert_id, [:pointer], :uint64
			attach_function :mysql_info, [:pointer], :string
			
			attach_function :mysql_close, [:pointer], :void
			attach_function :mysql_errno, [:pointer], :uint
			attach_function :mysql_error, [:pointer], :string
			
			attach_function :mysql_stat, [:pointer], :string
			
			attach_function :mysql_real_escape_string, [:pointer, :pointer, :string, :size_t], :size_t
			
			module IO
				def self.new(fd, mode)
					Async::IO::Generic.new(::IO.new(fd, mode, autoclose: false))
				end
			end
			
			class Connection < FFI::Pointer
				def self.connect(wrapper: IO, host: 'localhost', user: nil, password: nil, database: nil, port: 0, unix_socket: nil, client_flags: 0, compression: false, types: DEFAULT_TYPES, **options)
					pointer = Native.mysql_init(nil)
					Native.mysql_options(pointer, MYSQL_OPT_NONBLOCK, nil)
					
					client_flags |= CLIENT_MULTI_STATEMENT | CLIENT_MULTI_RESULTS
					
					if compression
						client_flags |= CLIENT_COMPRESSION
					end
					
					result = FFI::MemoryPointer.new(:pointer)
					
					status = Native.mysql_real_connect_start(result, pointer, host, user, password, database, port, unix_socket, client_flags);
					
					io = wrapper.new(Native.mysql_get_socket(pointer), "r+")
					
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
				
				def initialize(address, io, types, **options)
					super(address)
					
					@io = io
					@result = nil
					
					@types = types
				end
				
				def wait_for(status)
					if status & MYSQL_WAIT_READ
						@io.wait_readable
					elsif status & MYSQL_WAIT_WRITE
						@io.wait_writable
					end
				end
				
				def check_error!(message)
					if Native.mysql_errno(self) != 0
						raise Error, "#{message}: #{Native.mysql_error(self)}!"
					end
				end
				
				def status
					Native.mysql_stat(self)
				end
				
				def free_result
					if @result
						Native.mysql_free_result(@result)
						
						@result = nil
					end
				end
				
				def close
					self.free_result
					
					Native.mysql_close(self)
					
					@io.close
				end
				
				def escape(value)
					value = value.to_s
					
					maximum_length = value.bytesize * 2 + 1
					out = FFI::MemoryPointer.new(:char, maximum_length)
					
					Native.mysql_real_escape_string(self, out, value, value.bytesize)
					
					return out.read_string
				end
				
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
				
				# @returns [Boolean] If there are more results.
				def more_results?
					Native.mysql_more_results(self) == 1
				end
				
				def next_result(types: @types)
					if result = self.get_result
						return Result.new(self, types, result)
					end
				end
				
				# Silently discard any results that application didn't read.
				def discard_results
					while result = self.get_result
					end
					
					return nil
				end
				
				def affected_rows
					Native.mysql_affected_rows(self)
				end
				
				def insert_id
					Native.mysql_insert_id(self)
				end
				
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
