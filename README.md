# openregister-ruby
A Ruby API to UK government data registers http://www.openregister.org/

## Usage

### Retrieve list of registers

To retrieve all registers from register.gov.uk:

    OpenRegister.registers

To retrieve all registers from openregister.org:

    OpenRegister.registers from_openregister: true

Each record is a Ruby object:

    require 'yaml'
    puts OpenRegister.registers[1].to_yaml

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

### Retrieve a specific register's records

To retrieve all records from a specific register:

    register = OpenRegister.registers[1]
    records = register.records

Each record is a Ruby object with a class name derived from the register name:

    puts records.first.to_yaml

    --- !ruby/object:OpenRegister::Country
    serial_number: 201
    _hash: b24b537412095cd50fadce010fdeefeb5d3a4b71
    citizen_names: Gambian
    country: GM
    name: Gambia,The
    official_name: The Islamic Republic of The Gambia
