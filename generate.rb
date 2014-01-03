require 'json'

class Generator

	def initialize(file)
		@file = file
		@schema = nil

		File.open(file, 'r').each_line { |line|
			addLine line
		}
	end

	def addLine(json)
		obj = JSON.parse json, symbolize_names: true
		@schema = merge @schema, type(obj)
	end

	attr_reader :schema

	def definition
		@schema.map { |k,v|
			"#{k} #{out v}"
		} * ",\n"
	end

	def table(name = :test)
		"ADD JAR hive-json-serde-0.2.jar;\n\n" +
		"CREATE TABLE #{name} (\n" +
			definition +
		"\n) ROW FORMAT SERDE 'org.apache.hadoop.hive.contrib.serde2.JsonSerde';\n\n" +
		"LOAD DATA LOCAL INPATH '#{@file}' INTO TABLE #{name};"
	end

private

	RANK = [:tinyint, :smallint, :int, :bigint, :double]

	def out(data, i = 0, key = nil)
		pad = "\t" * i
		pad + ("#{key}: " if key).to_s + case data
		when Array
			"ARRAY<\n" + out(data.first, i+1) + "\n#{pad}>"
		when Hash
			"STRUCT<\n" + data.map { |k,v|
				out v, i+1, k
			} * ",\n" + "\n#{pad}>"
		when Integer
			RANK[data].to_s.upcase
		when NilClass
			'UNKNOWN'
		else
			data.to_s.upcase
		end
	end

	# vrne "skupni imenovalec shem"
	def merge(a, b)
		if [a, b].compact.size < 2
			return [a, b].compact.first
		end

		cuniq = [a, b].map(&:class).uniq
		case a
		when Array
			return [merge(a.first, b.first)]
		when Hash
			return a.merge(b) { |key, old, new|
				merge old, new
			}
		when Integer
			return [a, b].max
		end if cuniq.size == 1

		uniq = [a, b].uniq
		if uniq.size == 1
			uniq.first
		else
			raise "Mismatch: #{a}, #{b}"
		end
	end

	def type(var)
		case var
		when FalseClass, TrueClass
			:boolean
		when String
			:string
		when Integer
			case var
			when -128..127
				0 # tinyint
			when -32768..32767
				1 # smallint
			when -2147483648..2147483647
				2 # int
			when -9223372036854775808..9223372036854775807
				3 # bigint
			else
				4 # double
			end
		when Float
			4 # double
		when Hash
			Hash[ var.map { |k, v|
				[ k, type(v) ]
			} ]
		when Array
			[ if var.empty?
				nil
			else
				obj = type var.first
				var.drop(1).each { |el|
					obj = merge obj, type(el)
				}
				obj
			end ]
		end
	end

end

if ARGV[0]
	puts Generator.new(ARGV[0]).table ARGV[1] || :data
else
	puts "USAGE: ruby generate.rb sample.json [table_name]"
end