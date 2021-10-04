
require_relative "lib/db/mariadb/version"

Gem::Specification.new do |spec|
	spec.name = "db-mariadb"
	spec.version = DB::MariaDB::VERSION
	
	spec.summary = "An event-driven interface for MariaDB and MySQL servers."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/db-mariadb"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_dependency "async-io"
	spec.add_dependency "ffi-module", "~> 0.3.0"
	
	spec.add_development_dependency "async-rspec"
	spec.add_development_dependency "bake"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "rspec", "~> 3.6"
end
