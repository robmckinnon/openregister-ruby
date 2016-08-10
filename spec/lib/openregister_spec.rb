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

    allow(OpenRegister).to receive(:field).with('food-premises-types', anything).
      and_return double("OpenRegister::Field",
        register: 'food-premises-type', datatype: 'string', cardinality: 'n')

    [
      'https://register.register.gov.uk/records.tsv',
      'http://register.alpha.openregister.org/records.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-records.tsv')
    end

    [
      'https://register.register.gov.uk/record/register.tsv',
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-register.tsv')
    end

    [
      'https://register.register.gov.uk/record/country.tsv',
      'http://register.alpha.openregister.org/record/country.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-country.tsv')
    end

    [
      'http://register.alpha.openregister.org/record/food-premises-rating.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-food-premises-rating.tsv')
    end

    [
      'http://register.alpha.openregister.org/record/company.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-company.tsv')
    end

    [
      'http://register.alpha.openregister.org/record/premises.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-premises.tsv')
    end

    [
      'http://register.alpha.openregister.org/record/food-premises.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-food-premises.tsv')
    end

    stub_tsv_request('http://register.alpha.openregister.org/record/food-premises-type.tsv',
      './spec/fixtures/tsv/register-food-premises-type.tsv')

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

    stub_tsv_request('http://food-premises-type.alpha.openregister.org/record/Restaurant.tsv',
      './spec/fixtures/tsv/food-premises-type-restaurant.tsv')
  end

  describe 'retrieve registers index' do
    it 'returns array of Ruby objects' do
      records = OpenRegister.registers
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with('https://register.register.gov.uk/records', :register, nil, nil, true, 100)
      OpenRegister.registers
    end

    it 'sets _uri method on register returning uri correctly' do
      uri = OpenRegister.registers[1]._uri
      expect(uri).to eq('https://country.register.gov.uk/')
    end

    let(:cache) { double() }

    context 'with cache passed in' do
      it 'calls correct url' do
        expect(OpenRegister).to receive(:retrieve).with('https://register.register.gov.uk/records', :register, nil, cache, true, 100)
        OpenRegister.registers cache: cache
      end
    end

    context 'with cache passed in and no value for key' do
      it 'returns array of Ruby objects' do
        expect(cache).to receive(:read).with('https://register.register.gov.uk/records.tsv').and_return nil
        expect(cache).to receive(:write).with('https://register.register.gov.uk/records.tsv', [
          File.read('./spec/fixtures/tsv/register-records.tsv'), nil
        ])
        records = OpenRegister.registers cache: cache
        expect(records).to be_an(Array)
        records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
      end
    end

    context 'with cache passed in and value for key exists' do
      it 'returns array of Ruby objects' do
        expect(cache).to receive(:read).with('https://register.register.gov.uk/records.tsv').and_return([
          File.read('./spec/fixtures/tsv/register-records.tsv'), nil
        ])
        expect(cache).not_to receive(:write)
        records = OpenRegister.registers cache: cache
        expect(records).to be_an(Array)
        records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
      end
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
        'http://register.alpha.openregister.org/', nil, true, 100)
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
        :alpha, nil, true, 100)
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
      text: 'A premises which serves or processes food.',
      start_date: nil,
      end_date: nil,
    }
  end

  describe 'retrieve specific record from a given register' do
    let(:register) { 'food-premises' }
    let(:record) { '759332' }

    subject { OpenRegister.record(register, record, 'http://register.alpha.openregister.org/') }

    include_examples 'has attributes', {
      business: "company:07228130",
      food_premises: "759332",
      local_authority: "506",
      name: "Byron",
      premises: "15662079000",
      end_date: nil,
      start_date: nil,
      food_premises_types: ["Restaurant"],
    }

    it 'returns its uri' do
      expect(subject._uri).to eq('http://food-premises.alpha.openregister.org/record/759332')
    end

    it 'returns its curie' do
      expect(subject._curie).to eq('food-premises:759332')
    end

    it 'returns register from class method' do
      expect(subject.class.register).to eq('food-premises')
    end

    it 'returns linked record list from another register' do
      list = subject._food_premises_types
      expect(list).to be_a(Array)
      expect(list.first.class.name).to eq('OpenRegister::FoodPremisesType')
      expect(list.first.name).to eq('Restaurant')
    end

    it 'returns register object from class method' do
      register = subject.class._register(:alpha)
      expect(register.class.name).to eq('OpenRegister::Register')
      expect(register.register).to eq('food-premises')
    end

    it 'returns register object from instance method' do
      register = subject._register
      expect(register.class.name).to eq('OpenRegister::Register')
      expect(register.register).to eq('food-premises')
    end

    it 'returns register field objects from instance method' do
      fields = subject._register_fields
      expect(fields).to be_an(Array)
      expect(fields.size).to eq(8)
      fields.each do |r|
        expect(r).to be_a(RSpec::Mocks::Double)
        expect(r.instance_variable_get(:@name)).to eq("OpenRegister::Field")
      end
    end
  end
end
