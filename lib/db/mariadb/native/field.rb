# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require_relative "../native"

require_relative "types"

require "date"
require "json"

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
				primary_key: Types::Integer.new("BIGINT AUTO_INCREMENT PRIMARY KEY"),
				foreign_key: Types::Integer.new("BIGINT"),
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
				longlong: Types::Integer.new("LONGLONG"),
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
