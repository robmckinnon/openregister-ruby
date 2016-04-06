require_relative '../../lib/openregister'

RSpec.describe OpenRegister do

  def stub_tsv_request url, fixture, headers: {}
    stub_request(:get, url).
      to_return(status: 200,
        body: File.new(fixture),
        headers: { 'Content-Type': 'text/tab-separated-values;charset=UTF-8' }.merge(headers) )
  end

  before do
    allow(OpenRegister).to receive(:field).and_return double(register: '', datatype: 'string', cardinality: '1')
    allow(OpenRegister).to receive(:field).with('fields', from_openregister: false).
      and_return double(register: '', datatype: 'string', cardinality: 'n')

    [
      'https://register.register.gov.uk/records.tsv',
      'http://register.openregister.org/records.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-records.tsv')
    end

    [
      'https://country.register.gov.uk/records.tsv',
      'http://country.openregister.org/records.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/country-records-1.tsv',
        headers: { 'Link': '<?page-index=2&page-size=100>; rel="next"' })
    end

    [
      'https://country.register.gov.uk/records.tsv?page-index=2&page-size=100',
      'http://country.openregister.org/records.tsv?page-index=2&page-size=100'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/country-records-2.tsv',
        headers: { 'Link': '<?page-index=1&page-size=100>; rel="previous"' })
    end

    stub_tsv_request('http://food-premises-rating.openregister.org/records.tsv',
      './spec/fixtures/tsv/food-premises-rating-records.tsv')

    stub_tsv_request('http://field.openregister.org/field/food-premises.tsv',
      './spec/fixtures/tsv/food-premises.tsv')

    stub_tsv_request('http://food-premises.openregister.org/food-premises/759332.tsv',
      './spec/fixtures/tsv/food-premises-759332.tsv')

    stub_tsv_request('http://company.openregister.org/company/07228130.tsv',
      './spec/fixtures/tsv/company-07228130.tsv')

    stub_tsv_request('http://premises.openregister.org/premises/15662079000.tsv',
      './spec/fixtures/tsv/premises-15662079000.tsv')
  end

  describe 'retrieve registers index' do
    it 'returns array of Ruby objects' do
      records = OpenRegister.registers
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with('https://register.register.gov.uk/records', :register, false, true, 100)
      OpenRegister.registers from_openregister: false
    end
  end

  describe 'retrieve registers index from openregister.org' do
    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with('http://register.openregister.org/records', :register, true, true, 100)
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
      entry: '9',
      fields: ['country', 'name', 'official-name', 'citizen-names', 'start-date', 'end-date'],
      phase: 'alpha',
      register: 'country',
      registry: 'foreign-commonwealth-office',
      text: 'British English-language names and descriptive terms for countries'
    }
  end

  describe 'retrieve all a register\'s records handling pagination' do
    it 'returns records as Ruby objects' do
      records = OpenRegister.registers[1].all_records
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an(OpenRegister::Country) }
      expect(records.size).to eq(2)
    end
  end

  describe 'retrieve a register\'s records first page only' do
    it 'returns records as Ruby objects' do
      records = OpenRegister.registers[1].records
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an(OpenRegister::Country) }
      expect(records.size).to eq(1)
    end
  end

  shared_examples 'has record attributes' do
    include_examples 'has attributes', {
      entry: '201',
      citizen_names: 'Gambian',
      country: 'GM',
      name: 'Gambia,The',
      official_name: 'The Islamic Republic of The Gambia'
    }
  end

  describe 'retrieved register record' do
    subject { OpenRegister.registers[1].all_records[0] }

    include_examples 'has record attributes'
  end

  describe 'retrieved register record from openregister.org' do
    subject { OpenRegister.registers(from_openregister: true)[1].all_records[0] }

    include_examples 'has record attributes'
    include_examples 'has attributes', { from_openregister: true }
  end

  describe 'retrieve register by name' do
    it 'returns register' do
      register = OpenRegister.register('food-premises-rating', from_openregister: true)
      expect(register.register).to eq('food-premises-rating')
    end
  end

  describe 'retrieve a record linked to from another record' do
    it 'returns linked record from another register' do
      expect(OpenRegister).to receive(:field).with('food-premises', from_openregister: true).
        and_return double(register: 'food-premises', datatype: 'string', cardinality: '1')

      expect(OpenRegister).to receive(:field).with('business', from_openregister: true).
        and_return double(register: 'company', datatype: 'curie', cardinality: '1')

      expect(OpenRegister).to receive(:field).with('premises', from_openregister: true).
        and_return double(register: 'premises', datatype: 'string', cardinality: '1')

      register = OpenRegister.register('food-premises-rating', from_openregister: true)
      record = register.records.first
      expect(record._food_premises._business.class.name).to eq('OpenRegister::Company')
      expect(record._food_premises._premises.class.name).to eq('OpenRegister::Premises')
      expect(record._food_premises.class.name).to eq('OpenRegister::FoodPremises')
    end
  end

  shared_examples 'has field attributes' do
    include_examples 'has attributes', {
      entry: '24',
      cardinality: '1',
      datatype: 'string',
      field: 'food-premises',
      phase: 'alpha',
      register: 'food-premises',
      text: 'A premises which serves or processes food.'
    }
  end

  describe 'retrieve specific record from a given register' do
    subject { OpenRegister.record('field', 'food-premises', from_openregister: true) }
    include_examples 'has field attributes'
  end
end
