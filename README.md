# openregister-ruby
A Ruby API to UK government data registers http://www.openregister.org/

## Usage

### Retrieve list of registers

To retrieve all registers from [register.gov.uk](https://register.register.gov.uk/records):

```rb
OpenRegister.registers
```

To retrieve all registers from [alpha.openregister.org](http://register.alpha.openregister.org/records):

```rb
OpenRegister.registers from_openregister: true
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
```

### Retrieve a specific register's records

To retrieve all records from a specific register:

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

### Retrieve records linked from a specific record

Retrieve a food premises rating:

```rb
register = OpenRegister.register 'food-premises-rating', from_openregister: true
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
_from_openregister: true
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
_from_openregister: true
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
_from_openregister: true
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
_from_openregister: true
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
_from_openregister: true
```
