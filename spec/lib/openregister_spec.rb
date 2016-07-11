require_relative '../../lib/openregister'

RSpec.describe OpenRegister do

  def stub_tsv_request url, fixture, headers: {}
    stub_request(:get, url).
      to_return(status: 200,
        body: File.new(fixture),
        headers: { 'Content-Type': 'text/tab-separated-values;charset=UTF-8' }.merge(headers) )
  end

  before do
    allow(OpenRegister).to receive(:field).and_return double("OpenRegister::Field",
      register: '', datatype: 'string', cardinality: '1')

    allow(OpenRegister).to receive(:field).with('fields', anything).
      and_return double("OpenRegister::Field",
        register: '', datatype: 'string', cardinality: 'n')

    [
      'https://register.register.gov.uk/records.tsv',
      'http://register.alpha.openregister.org/records.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-records.tsv')
    end

    [
      'https://country.register.gov.uk/records.tsv',
      'http://country.alpha.openregister.org/records.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/country-records-1.tsv',
        headers: { 'Link': '<?page-index=2&page-size=100>; rel="next"' })
    end

    [
      'https://country.register.gov.uk/records.tsv?page-index=2&page-size=100',
      'http://country.alpha.openregister.org/records.tsv?page-index=2&page-size=100'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/country-records-2.tsv',
        headers: { 'Link': '<?page-index=1&page-size=100>; rel="previous"' })
    end

    stub_tsv_request('http://food-premises-rating.alpha.openregister.org/records.tsv',
      './spec/fixtures/tsv/food-premises-rating-records.tsv')

    stub_tsv_request('http://field.alpha.openregister.org/record/food-premises.tsv',
      './spec/fixtures/tsv/food-premises.tsv')

    stub_tsv_request('http://food-premises.alpha.openregister.org/record/759332.tsv',
      './spec/fixtures/tsv/food-premises-759332.tsv')

    stub_tsv_request('http://company.alpha.openregister.org/record/07228130.tsv',
      './spec/fixtures/tsv/company-07228130.tsv')

    stub_tsv_request('http://premises.alpha.openregister.org/record/15662079000.tsv',
      './spec/fixtures/tsv/premises-15662079000.tsv')
  end

  describe 'retrieve registers index' do
    it 'returns array of Ruby objects' do
      records = OpenRegister.registers
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with('https://register.register.gov.uk/records', :register, nil, true, 100)
      OpenRegister.registers
    end

    it 'sets _uri method on register returning uri correctly' do
      uri = OpenRegister.registers[1]._uri
      expect(uri).to eq('https://country.register.gov.uk/')
    end
  end

  describe 'retrieve registers index when passed base_url' do
    it 'returns array of Ruby objects with from_openregister set true' do
      records = OpenRegister.registers 'http://register.alpha.openregister.org/'
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
      records.each { |r| expect(r._base_url_or_phase).to eq('http://register.alpha.openregister.org/') }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with(
        'http://register.alpha.openregister.org/records', :register,
        'http://register.alpha.openregister.org/', true, 100)
      OpenRegister.registers 'http://register.alpha.openregister.org/'
    end

    it 'sets _uri method on register returning uri correctly' do
      uri = OpenRegister.registers('http://register.alpha.openregister.org/')[1]._uri
      expect(uri).to eq('http://country.alpha.openregister.org/')
    end
  end

  describe 'retrieve registers index when passed phase' do
    it 'returns array of Ruby objects with from_openregister set true' do
      records = OpenRegister.registers :alpha
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
      records.each { |r| expect(r._base_url_or_phase).to eq(:alpha) }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with(
        'http://register.alpha.openregister.org/records', :register,
        :alpha, true, 100)
      OpenRegister.registers :alpha
    end

    it 'sets _uri method on register returning uri correctly' do
      uri = OpenRegister.registers(:alpha)[1]._uri
      expect(uri).to eq('http://country.alpha.openregister.org/')
    end
  end

  shared_examples 'has attributes' do |hash|
    hash.each do |attribute, value|
      it { is_expected.to have_attributes(attribute => value) }
    end
  end

  describe 'retrieved record' do
    subject { OpenRegister.registers[1] }

    it 'has fields converted to array', focus: true do
      fields = subject.instance_variable_get('@fields')
      expect(fields).to eql(['country', 'name', 'official-name', 'citizen-names', 'start-date', 'end-date'])
    end

    include_examples 'has attributes', {
      entry_number: '3',
      fields: ['country', 'name', 'official-name', 'citizen-names', 'start-date', 'end-date'],
      phase: 'beta',
      register: 'country',
      registry: 'foreign-commonwealth-office',
      text: 'British English-language names and descriptive terms for countries'
    }
  end

  describe 'retrieve all a register\'s records handling pagination via #_all_records' do
    it 'returns records as Ruby objects' do
      records = OpenRegister.registers[1]._all_records
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an(OpenRegister::Country) }
      expect(records.size).to eq(2)
    end
  end

  describe 'retrieve a register\'s records first page only via #_records' do
    it 'returns records as Ruby objects' do
      records = OpenRegister.registers[1]._records
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an(OpenRegister::Country) }
      expect(records.size).to eq(1)
    end
  end

  describe 'retrieve a register\'s fields via #_fields' do
    it 'returns fields as Ruby objects' do
      register = OpenRegister.registers[1]
      fields = register._fields
      expect(fields).to be_an(Array)
      expect(fields.size).to eq(6)
      fields.each do |r|
        expect(r).to be_a(RSpec::Mocks::Double)
        expect(r.instance_variable_get(:@name)).to eq("OpenRegister::Field")
      end
    end
  end

  shared_examples 'has record attributes' do
    include_examples 'has attributes', {
      entry_number: '202',
      citizen_names: 'Gambian',
      country: 'GM',
      name: 'The Gambia',
      official_name: 'The Islamic Republic of The Gambia',
      entry_timestamp: '2016-04-05T13:23:05Z',
    }
  end

  describe 'retrieved register record' do
    subject { OpenRegister.registers[1]._all_records[0] }

    include_examples 'has record attributes'
  end

  describe 'retrieved register record when passed base_url' do
    subject { OpenRegister.registers('http://register.alpha.openregister.org/')[1]._all_records[0] }

    include_examples 'has record attributes'
    include_examples 'has attributes', { _base_url_or_phase: 'http://register.alpha.openregister.org/' }
  end

  describe 'retrieve register by name' do
    subject { OpenRegister.register('food-premises-rating', 'http://register.alpha.openregister.org/') }

    it 'returns register' do
      expect(subject.register).to eq('food-premises-rating')
    end

    it 'has _uri method returning uri correctly' do
      expect(subject._uri).to eq('http://food-premises-rating.alpha.openregister.org/')
    end
  end

  describe 'retrieve a record linked to from another record' do
    it 'returns linked record from another register' do
      expect(OpenRegister).to receive(:field).with('food-premises', :alpha).
        and_return double(register: 'food-premises', datatype: 'string', cardinality: '1')

      expect(OpenRegister).to receive(:field).with('business', :alpha).
        and_return double(register: 'company', datatype: 'curie', cardinality: '1')

      expect(OpenRegister).to receive(:field).with('premises', :alpha).
        and_return double(register: 'premises', datatype: 'string', cardinality: '1')

      register = OpenRegister.register('food-premises-rating', :alpha)
      record = register._records.first
      expect(record._food_premises._business.class.name).to eq('OpenRegister::Company')
      expect(record._food_premises._premises.class.name).to eq('OpenRegister::Premises')
      expect(record._food_premises.class.name).to eq('OpenRegister::FoodPremises')
    end
  end

  shared_examples 'has field attributes' do
    include_examples 'has attributes', {
      entry_number: '352',
      cardinality: '1',
      datatype: 'string',
      field: 'food-premises',
      phase: 'alpha',
      register: 'food-premises',
      text: 'A premises which serves or processes food.'
    }
  end

  describe 'retrieve specific record from a given register' do
    subject { OpenRegister.record('field', 'food-premises', 'http://register.alpha.openregister.org/') }
    include_examples 'has field attributes'
  end
end
