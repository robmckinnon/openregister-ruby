# openregister-ruby
A Ruby API to UK government data registers http://www.openregister.org/

[![Build Status](https://travis-ci.org/robmckinnon/openregister-ruby.svg?branch=master)](https://travis-ci.org/robmckinnon/openregister-ruby)

## Install

In your Gemfile add:

```rb
gem 'openregister-ruby', git: 'https://github.com/robmckinnon/openregister-ruby.git'
```

To use:

```rb
require 'openregister'
```

### Caching

To cache API call results, set a cache object that responds to `read` and `write` methods, e.g. a cache supporting the
[ActiveSupport::Cache::Store](http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html) interface would work.

For example, in a Rails app you can create a file in `config/initializers` to set the Rails cache on OpenRegister:

```rb
require 'openregister'
OpenRegister.cache = Rails.cache
```

## Usage

### Retrieve list of registers

To retrieve all registers from [register.gov.uk](https://register.register.gov.uk/records):

```rb
require 'openregister'

OpenRegister.registers
```

To retrieve all registers for a earlier register phase, pass the phase as a symbol. For example to retrieve all
registers from [alpha.openregister.org](http://register.alpha.openregister.org/records):

```rb
OpenRegister.registers :alpha
```

Or to retrieve all registers from a specific url pass the base_url as a string. For example to retrieve all registers
from [alpha.openregister.org](http://register.alpha.openregister.org/records), you can also call:

```rb
OpenRegister.registers 'http://register.alpha.openregister.org/'
```

Each record is a Ruby object:

```rb
require 'yaml'
puts OpenRegister.registers[1].to_yaml
```

```yml
--- !ruby/object:OpenRegister::Register
entry_number: '3'
item_hash: sha-256:610bde42d3ae2ed3dd829263fe461542742a10ca33865d96d31ae043b242c300
entry_timestamp: '2016-04-20T14:57:35Z'
register: country
text: British English-language names and descriptive terms for countries
registry: foreign-commonwealth-office
phase: beta
fields:
- country
- name
- official-name
- citizen-names
- start-date
- end-date
_uri: https://country.register.gov.uk/
```

### Retrieve a specific register's records

To retrieve first page of paginated records from a specific register:

```rb
register = OpenRegister.registers[1]
records = register._records
```

Each record is a Ruby object with a class name derived from the register name:

```rb
puts records.first.to_yaml
```

```yml
--- !ruby/object:OpenRegister::Country
entry_number: '204'
item_hash: sha-256:466d194d5100532edd115e3f0035967b09bc7b7f5fc444166df6f4a5f7cb9127
entry_timestamp: '2016-04-05T13:23:05Z'
country: VA
name: Vatican City
official_name: Vatican City State
citizen_names: Vatican citizen
```

To retrieve all records from a specific register that has a few hundred records
by paginating through all pages:

```rb
register._all_records
```

**Warning:** it is _not recommended_ to use `_all_records` on registers that
contain millions of records. It would be _extremely_ slow, and you may run out of
memory as all data returned is held in memory.

You can set the page size when retrieving all records as follows, default value
is 100, currently max page_size supported by the HTTP register API is 5,000:

```rb
register._all_records(page_size: 1000)
```

### Retrieve field definitions for a specific register

To retrieve all field details for a specific register:

```rb
register = OpenRegister.register 'country'
fields = register._fields
```

Each field is returned as a Ruby object:

```rb
puts fields.first.to_yaml
```

```yml
--- !ruby/object:OpenRegister::Field
entry_number: '8'
item_hash: sha-256:5a110f91639ee80def2a3bc5293d1130599ca82547402cfd6786a425ffe9b419
entry_timestamp: '2016-04-20T14:57:11Z'
field: country
datatype: string
phase: beta
register: country
cardinality: '1'
text: ISO 3166-2 two letter code for a country.
```

### Retrieve records linked from a specific record

Retrieve a food premises rating:

```rb
register = OpenRegister.register 'food-premises-rating', :discovery
rating = register._records.first
```

```yml
--- !ruby/object:OpenRegister::FoodPremisesRating
entry_number: '512920'
item_hash: sha-256:59113a9ba41c0c0f019f70003b96d76cb7795a34a1e16514d0cd4c9e42079fda
entry_timestamp: '2016-03-22T10:50:30Z'
food_premises_rating: 7593322014-04-09
food_premises: '759332'
food_premises_rating_value: '4'
food_premises_rating_hygiene_score: '5'
food_premises_rating_structural_score: '10'
food_premises_rating_confidence_in_management_score: '5'
start_date: '2014-04-09'
inspector: local-authority:506
_base_url_or_phase: :discovery
```

The record objects have methods prefixed with '_'
for retrieving associated data records.

For example, the rating above has an inspector value of
`local-authority:506`. To retrieve the inspector record for
this reference, call `_inspector` on the rating:

```rb
rating._inspector
```

```yml
--- !ruby/object:OpenRegister::LocalAuthority
entry_number: '407'
item_hash: sha-256:efb42866fdd5abdc3039d9b90544c352489297a66f70e76761c79f65bd29ed8f
entry_timestamp: '2016-03-31T12:21:09Z'
local_authority: '506'
name: Camden
website: https://www.camden.gov.uk
_base_url_or_phase: :discovery
```

Retrieve the food premises from the rating:

```rb
rating._food_premises
```

```yml
--- !ruby/object:OpenRegister::FoodPremises
entry_number: '11'
item_hash: sha-256:cdb325272d9f0d658616f9c36e3de595fc2b5ce51091696283cf2ca1d3d5741f
entry_timestamp: '2016-03-22T10:43:15Z'
food_premises: '759332'
name: Byron
business: company:07228130
local_authority: '506'
premises: '15662079000'
_base_url_or_phase: :discovery
```

Retrieve the business from the food premises:

```rb
rating._food_premises._business
```

```yml
--- !ruby/object:OpenRegister::Company
entry_number: '2'
item_hash: sha-256:454a74d390dcaa13d999a756b0eb933b81e03c909099e4bb26b1faffc26b5a93
entry_timestamp: '2016-03-31T12:15:49Z'
company: 07228130
name: BYRON HAMBURGERS LIMITED
registered_office: '10033530330'
industry: '56101'
start_date: '2010-04-20'
_base_url_or_phase: :discovery
```

Retrieve the industry from the business:

```rb
rating._food_premises._business._industry
```

```yml
--- !ruby/object:OpenRegister::Industry
entry_number: '1352'
item_hash: sha-256:285a2fbb621fd898ecaa76bab487c2ec103887a4130500be296d5dca5248e46b
entry_timestamp: '2016-03-31T13:44:24Z'
industry: '56101'
name: 'Licensed restaurants '
_base_url_or_phase: :discovery
```

### Retrieve record by primary key value

You can retrieve a
[record](https://openregister.github.io/specification/#record-resource) with a
given primary key field value from a register using the `record` method:

```rb
prison = OpenRegister.record 'prison', 'MR', :alpha
```

### Retrieve entries for a primary key

You can retrieve all
[entries](https://openregister.github.io/specification/#entry-resource) with a
given primary key field value from a register using the `entries` method:

```rb
entries = OpenRegister.entries 'prison', 'MH', :alpha

puts entries.map {|x| [x.entry_number, x.item_hash, x.entry_timestamp].join("\t")}
77	sha-256:6aa9bcb4a409e3026560ea338b365be55cf3f653a66ba2586fb206b83a7be722	2017-03-03T15:44:08Z
78	sha-256:f2eb99fa4d3bda2a451f62153e85374cd5c8a44933498ec7077f214581fd179f	2017-03-03T15:44:08Z
```

### Retrieve versions for a primary key [experimental]

You can retrieve all entries combined with associated
[item](https://openregister.github.io/specification/#item-resource) fields using
the `versions` method:

```rb
versions = OpenRegister.versions 'prison', 'MH', :alpha

puts versions.map{|x| [x.entry_number, x.prison, x.name, x.change_date].join("\t")}
77	MH	HMP Morton Hall
78	MH	HMIRC Morton Hall	2011-05
```

This is an experimental feature, and is subject to change.

### Show version changes [experimental] for a records

You can retrieve a list of hashes representing fields that have changed across
entries for a given primary key field value using `_version_changes` method:

```rb
prison = OpenRegister.record 'prison', 'MR', :alpha

prison._version_changes
=> [
    {"entry-number"=>"77", "name"=>"HMP Morton Hall", "change-date"=>nil},
    {"entry-number"=>"78", "name"=>"HMIRC Morton Hall", "change-date"=>"2011-05", "-uri"=>"http://prison.alpha.openregister.org/record/MH"}
   ]
```

This is an experimental feature, and is subject to change.

### Show version change description text [experimental]

You can get text showing version changes description for a given field using
`_version_change_display`:

```rb
prison._version_change_display(:name, :start_date, :change_date)
=> ["HMP Morton Hall  - 2011-05"]
```

This is an experimental feature, and is subject to change.
