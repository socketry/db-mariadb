# frozen_string_literal: true

require_relative "lib/db/mariadb/version"

Gem::Specification.new do |spec|
	spec.name = "db-mariadb"
	spec.version = DB::MariaDB::VERSION
	
	spec.summary = "An event-driven interface for MariaDB and MySQL servers."
	spec.authors = ["Samuel Williams", "Hal Brodigan"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/db-mariadb"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/db-mariadb/",
		"funding_uri" => "https://github.com/sponsors/ioquatix",
		"source_code_uri" => "https://github.com/socketry/db-mariadb.git",
	}
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"
	
	spec.add_dependency "async-pool"
	spec.add_dependency "bigdecimal"
	spec.add_dependency "ffi-module", "~> 0.3.0"
end
