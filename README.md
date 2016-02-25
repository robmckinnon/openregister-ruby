# openregister-ruby
A Ruby API to UK government data registers http://www.openregister.org/

## Usage

### Retrieve list of registers

To retrieve all records from the register register:

    OpenRegister.registers

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
