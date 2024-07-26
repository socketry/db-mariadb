# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require 'ffi/module'
require 'ffi/module/config_tool'

module DB
	module MariaDB
		module Native
			extend FFI::Module::Library
			extend FFI::Module::Loader
			extend FFI::Module::ConfigTool
			
			ffi_load('mariadb') ||
				ffi_load_using_config_tool(%w{mariadb_config --libs}) ||
				ffi_load_using_config_tool(%w{mysql_config --libs}) ||
				ffi_load_failure(<<~EOF)
					Unable to load libmariadb!
					
					## Ubuntu
					
						sudo apt-get install libmariadb-dev
					
					## Arch Linux
					
						sudo pacman -S mariadb
					
					## MacPorts
					
						sudo port install mariadb-10.5
						sudo port select --set mysql mariadb-10.5
					
					## Homebrew
					
						brew install mariadb
					
				EOF
		end
	end
end
