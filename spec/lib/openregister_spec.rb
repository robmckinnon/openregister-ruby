require_relative '../../lib/openregister'

RSpec.describe OpenRegister do

  before do
    [
      "https://register.register.gov.uk/records.json",
      "http://register.openregister.org/records.json"
    ].each do |url|
      stub_request(:get, url).
        to_return(status: 200,
          body: File.new('./spec/fixtures/register-records.json'),
          headers: { 'Content-Type': 'application/json' })
    end

    [
      "https://country.register.gov.uk/records.json",
      "http://country.openregister.org/records.json"
    ].each do |url|
      stub_request(:get, url).
        to_return(status: 200, body: File.new('./spec/fixtures/country-records-1.json'),
          headers: {
            'Content-Type': 'application/json',
            'Link': '<?page-index=2&page-size=100>; rel="next"'
          })
    end

    [
      "https://country.register.gov.uk/records.json?page-index=2&page-size=100",
      "http://country.openregister.org/records.json?page-index=2&page-size=100"
    ].each do |url|
      stub_request(:get, url).
        to_return(status: 200, body: File.new('./spec/fixtures/country-records-2.json'),
          headers: {
            'Content-Type': 'application/json',
            'Link': '<?page-index=1&page-size=100>; rel="previous"'
          })
    end

    stub_request(:get, "http://food-premises-rating.openregister.org/records.json").
        to_return(status: 200, body: File.new('./spec/fixtures/food-premises-rating-records.json'),
          headers: {
            'Content-Type': 'application/json'
          })

    stub_request(:get, "http://field.openregister.org/field/food-premises.json").
        to_return(status: 200, body: File.new('./spec/fixtures/field-food-premises.json'),
          headers: {
            'Content-Type': 'application/json'
          })
  end

  describe 'retrieve registers index' do
    it 'returns array of Ruby objects' do
      records = OpenRegister.registers
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with('https://register.register.gov.uk/records', :register, false)
      OpenRegister.registers from_openregister: false
    end
  end

  describe 'retrieve registers index from openregister.org' do
    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with('http://register.openregister.org/records', :register, true)
      OpenRegister.registers from_openregister: true
    end

    it 'returns array of Ruby objects with from_openregister set true' do
      records = OpenRegister.registers from_openregister: true
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
      records.each { |r| expect(r.from_openregister).to be(true) }
    end
  end

  shared_examples 'has attributes' do |hash|
    hash.each do |attribute, value|
      it { is_expected.to have_attributes(attribute => value) }
    end
  end

  describe 'retrieved record' do
    subject { OpenRegister.registers[1] }

    include_examples 'has attributes', {
      serial_number: 9,
      _hash: '247cf017d1b91ca8e0cd3abb60712224c6fa2b03',
      fields: ['country', 'name', 'official-name', 'citizen-names', 'start-date', 'end-date'],
      phase: 'alpha',
      register: 'country',
      registry: 'foreign-commonwealth-office',
      text: 'British English-language names and descriptive terms for countries'
    }
  end

  describe 'retrieve a register\'s records handling pagination' do
    it 'returns records as Ruby objects' do
      records = OpenRegister.registers[1].records
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an(OpenRegister::Country) }
      expect(records.size).to eq(2)
    end
  end

  describe 'retrieved register record' do
    subject { OpenRegister.registers[1].records[0] }

    include_examples 'has attributes', {
      serial_number: 201,
      _hash: 'b24b537412095cd50fadce010fdeefeb5d3a4b71',
      citizen_names: "Gambian",
      country: "GM",
      name: "Gambia,The",
      official_name: "The Islamic Republic of The Gambia"
    }
  end

  describe 'retrieved register record from openregister.org' do
    subject { OpenRegister.registers(from_openregister: true)[1].records[0] }

    include_examples 'has attributes', {
      serial_number: 201,
      _hash: 'b24b537412095cd50fadce010fdeefeb5d3a4b71',
      citizen_names: "Gambian",
      country: "GM",
      name: "Gambia,The",
      official_name: "The Islamic Republic of The Gambia",
      from_openregister: true
    }
  end

  describe 'retrieve register by name' do
    it 'returns register' do
      register = OpenRegister.register('food-premises-rating', from_openregister: true)
      expect(register.register).to eq('food-premises-rating')
    end
  end

  describe 'retrieve specific record from a given register' do
    subject { OpenRegister.record('field', 'food-premises', from_openregister: true) }

    include_examples 'has attributes', {
      serial_number: 24,
      _hash: 'b6a6f32b15f3aa55327b97c4729413f7bf0d321f',
      cardinality: "1",
      datatype: "string",
      field: "food-premises",
      phase: "alpha",
      register: "food-premises",
      text: "A premises which serves or processes food."
    }
  end

end
