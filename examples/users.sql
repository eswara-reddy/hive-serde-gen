ADD JAR hive-json-serde-0.2.jar;

CREATE TABLE users_table (
id TINYINT,
name STRING,
income UNKNOWN,
city STRUCT<
	name: STRING,
	area: DOUBLE
>,
children ARRAY<
	STRUCT<
		name: STRING,
		toy: STRING
	>
>
) ROW FORMAT SERDE 'org.apache.hadoop.hive.contrib.serde2.JsonSerde';

LOAD DATA LOCAL INPATH 'examples/users.json' INTO TABLE users_table;
