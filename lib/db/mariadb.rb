# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative 'mariadb/native'
require_relative 'mariadb/connection'

require_relative 'mariadb/adapter'

require 'db/adapters'
DB::Adapters.register(:mariadb, DB::MariaDB::Adapter)
