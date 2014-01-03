hive-serde-gen
==============

Generate Hive SerDe schema based on the JSON. This program accepts a JSON file and outputs the SerDe schema.

Example
---
Let's say we have the following JSON in the file `users.json`.

```json
{"id":1, "name":"Rok", "income":null, "city":{"name":"Grosuplje", "area":"12544.4"}, "children":[{"name":"Matej"}]}
{"id":2, "name":"Melanija", "children":[]}
{"id":3, "name":"Simon", "city":{"name":"Spodnji breg", "area":"12362.2354"}, "children":[{"name":"Simonca"},{"name":"Matic", "toy":"Ropotulica"}]}
```

Now we run `ruby generate.rb users.json users_table` and we get the following output. The output can then be either copied or redirected to the output file file.

```
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

LOAD DATA LOCAL INPATH 'users.json' INTO TABLE users_table;
```

As you can see, `income` is listed as `UNKNOWN`, because all data is either `null` or not present. You have to edit this before executing it using Hive.

All the above files are present in the `examples/` directory.

Schema requirements
---

- JSON has to be valid, one record per line
- Data in the same column has to be of the same or compatible type (`INT` and `DOUBLE` are compatible, data is cast to the greater type), otherwise you get a mismatch error:

```
generate.rb:79:in `merge': Mismatch: boolean, string (RuntimeError)
```

System requirements
---

Ruby 2.0 or higher
