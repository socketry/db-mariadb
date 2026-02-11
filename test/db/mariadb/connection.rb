# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2026, by Samuel Williams.

require "db/mariadb/connection"
require "sus/fixtures/async"

describe DB::MariaDB::Connection do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:connection) {subject.new(**CREDENTIALS)}
	
	after do
		@connection&.close
	end
	
	it "should connect to local server" do
		expect(connection.status).to be(:include?, "Uptime")
	end
	
	it "should execute query" do
		connection.send_query("SELECT 42 AS LIFE")
		
		result = connection.next_result
		
		expect(result.to_a).to be == [[42]]
	end
	
	it "can list tables" do
		connection.send_query("SELECT * FROM INFORMATION_SCHEMA.TABLES")
		
		result = connection.next_result
		
		expect(result.to_a).not.to be(:empty?)
	end
	
	it "can get current time" do
		connection.send_query("SELECT UTC_TIMESTAMP() AS NOW")
		
		result = connection.next_result
		row = result.to_a.first
		
		expect(row.first).to be_within(1).of(Time.now.utc)
	end
	
	with "#append_string" do
		it "should escape string" do
			expect(connection.append_string("Hello 'World'")).to be == "'Hello \\'World\\''"
			expect(connection.append_string('Hello "World"')).to be == "'Hello \\\"World\\\"'"
		end
	end
	
	with "#append_literal" do
		it "should escape string" do
			expect(connection.append_literal("Hello World")).to be == "'Hello World'"
		end
		
		it "should not escape integers" do
			expect(connection.append_literal(42)).to be == "42"
		end
	end
	
	with "#append_identifier" do
		it "should escape identifier" do
			expect(connection.append_identifier("Hello World")).to be == "`Hello World`"
		end
		
		it "can handle booleans" do
			buffer = String.new
			buffer << "SELECT "
			connection.append_literal(true, buffer)
			
			connection.send_query(buffer)
			
			result = connection.next_result
			row = result.to_a.first
			
			expect(row.first).to be == true
		end
	end
	
	with "#features" do
		it "should return configured MariaDB features" do
			features = connection.features
			
			expect(features.modify_column?).to be == true
			expect(features.conditional_operations?).to be == true
			expect(features.batch_alter_table?).to be == true
			expect(features.alter_column_type?).to be == false
			expect(features.using_clause?).to be == false
			expect(features.transactional_schema?).to be == false
		end
	end
end
