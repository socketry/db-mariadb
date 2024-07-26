# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require 'db/mariadb/connection'
require 'sus/fixtures/async'

describe DB::MariaDB::Connection do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:connection) {subject.new(**CREDENTIALS)}
	
	it "should connect to local server" do
		expect(connection.status).to be(:include?, "Uptime")
	ensure
		connection.close
	end
	
	it "should execute query" do
		connection.send_query("SELECT 42 AS LIFE")
		
		result = connection.next_result
		
		expect(result.to_a).to be == [[42]]
	ensure
		connection.close
	end
	
	it "can list tables" do
		connection.send_query("SELECT * FROM INFORMATION_SCHEMA.TABLES")
		
		result = connection.next_result
		
		expect(result.to_a).not.to be(:empty?)
	ensure
		connection.close
	end
	
	it "can get current time" do
		connection.send_query("SELECT UTC_TIMESTAMP() AS NOW")
		
		result = connection.next_result
		row = result.to_a.first
		
		expect(row.first).to be_within(1).of(Time.now.utc)
	ensure
		connection.close
	end
	
	with '#append_string' do
		it "should escape string" do
			expect(connection.append_string("Hello 'World'")).to be == "'Hello \\'World\\''"
			expect(connection.append_string('Hello "World"')).to be == "'Hello \\\"World\\\"'"
		ensure
			connection.close
		end
	end
	
	with '#append_literal' do
		it "should escape string" do
			expect(connection.append_literal("Hello World")).to be == "'Hello World'"
		ensure
			connection.close
		end
		
		it "should not escape integers" do
			expect(connection.append_literal(42)).to be == "42"
		ensure
			connection.close
		end
	end
	
	with '#append_identifier' do
		it "should escape identifier" do
			expect(connection.append_identifier("Hello World")).to be == "`Hello World`"
		ensure
			connection.close
		end
		
		it "can handle booleans" do
			buffer = String.new
			buffer << "SELECT "
			connection.append_literal(true, buffer)
			
			connection.send_query(buffer)
			
			result = connection.next_result
			row = result.to_a.first
			
			expect(row.first).to be == true
		ensure
			connection.close
		end
	end
end
