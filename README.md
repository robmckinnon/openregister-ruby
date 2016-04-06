# openregister-ruby
A Ruby API to UK government data registers http://www.openregister.org/

## Usage

### Retrieve list of registers

To retrieve all registers from [register.gov.uk](https://register.register.gov.uk/records):

```rb
OpenRegister.registers
```

To retrieve all registers from [openregister.org](http://register.openregister.org/records):

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
serial_number: 9
_hash: 247cf017d1b91ca8e0cd3abb60712224c6fa2b03
fields:
- country
- name
- official-name
- citizen-names
- start-date
- end-date
phase: alpha
register: country
registry: foreign-commonwealth-office
text: British English-language names and descriptive terms for countries
```

### Retrieve a specific register's records

To retrieve all records from a specific register:

```rb
register = OpenRegister.registers[1]
records = register.records
```

Each record is a Ruby object with a class name derived from the register name:

```rb
puts records.first.to_yaml
```

```yml
--- !ruby/object:OpenRegister::Country
serial_number: 201
_hash: b24b537412095cd50fadce010fdeefeb5d3a4b71
citizen_names: Gambian
country: GM
name: Gambia,The
official_name: The Islamic Republic of The Gambia
```

### Retrieve records linked from a specific record

Retrieve a food premises rating:

```rb
register = OpenRegister.register 'food-premises-rating', from_openregister: true
rating = register.records.first
```

```yml
--- !ruby/object:OpenRegister::FoodPremisesRating
serial_number: 512920
_hash: cf0caf7777c57ddc4c7dec859f186ac34b4b6733
food_premises: '759332'
food_premises_rating: 7593322014-04-09
food_premises_rating_confidence_in_management_score: '5'
food_premises_rating_hygiene_score: '5'
food_premises_rating_structural_score: '10'
food_premises_rating_value: '4'
inspector: local-authority:506
start_date: '2014-04-09'
from_openregister: true
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
serial_number: 408
_hash: e124e235606b8de334803031567fe4d8e5903ffa
local_authority: '506'
name: Camden
website: https://www.camden.gov.uk
from_openregister: true
```

Retrieve the food premises from the rating:

```rb
rating._food_premises
```

```yml
--- !ruby/object:OpenRegister::FoodPremises
serial_number: 11
_hash: 831dab74ad10d89d4d23e167e42a9691a0e77fca
business: company:07228130
food_premises: '759332'
food_premises_types: []
local_authority: '506'
name: Byron
premises: '15662079000'
from_openregister: true
```

Retrieve the business from the food premises:

```rb
rating._food_premises._business
```

```yml
--- !ruby/object:OpenRegister::Company
serial_number: 4
_hash: e6b3efd149ae1945f0b6228db7f89eba1f14dd9b
company: 07228130
industry: '56101'
name: BYRON HAMBURGERS LIMITED
registered_office: '10033530330'
start_date: '2010-04-20'
from_openregister: true
```

Retrieve the industry from the business:

```rb
rating._food_premises._business._industry
```

```yml
--- !ruby/object:OpenRegister::Industry
serial_number: 546
_hash: 0fbe953759c82b8b9309ba9f4a89277b716ee872
industry: '56101'
name: 'Licensed restaurants '
from_openregister: true
```
