require 'rails_helper'

describe DomainChecker do
  let(:valid_domain) { 'example.com' }
  let(:invalid_domain) { 'bad_domain' }
  let(:blank_domain) { '' }
  let(:mixed_case_domain) { 'ExAmPlE.CoM' }
  let(:unsupported_domain) { 'unsupported.tld' }
  let(:whois_client) { instance_double(Whois::Client) }
  let(:whois_record) { instance_double(Whois::Record) }
  let(:whois_parser) { double('Whois::Parser', available?: true) }

  before do
    allow(Whois::Client).to receive(:new).and_return(whois_client)
    allow(whois_client).to receive(:lookup).and_return(whois_record)
  end

  it 'recognizes valid domain format' do
    expect(DomainChecker.new(valid_domain).valid_format?).to be true
  end

  it 'recognizes invalid domain format' do
    expect(DomainChecker.new(invalid_domain).valid_format?).to be false
  end

  it 'handles blank domain input' do
    checker = DomainChecker.new(blank_domain).check
    expect(checker.error).to match(/Please enter a domain name/)
    expect(checker.available).to be_nil
  end

  it 'handles invalid domain format' do
    checker = DomainChecker.new(invalid_domain).check
    expect(checker.error).to match(/Invalid domain format/)
    expect(checker.available).to be_nil
  end

  it 'downcases and strips domain before check' do
    allow(whois_client).to receive(:lookup).with('example.com').and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    checker = DomainChecker.new('  ExAmPlE.CoM  ').check
    expect(checker.domain).to eq('example.com')
    expect(checker.available).to be true
  end

  it 'handles available domains' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    checker = DomainChecker.new(valid_domain).check
    expect(checker.available).to be true
    expect(checker.error).to be_nil
  end

  it 'handles taken domains' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(false)
    checker = DomainChecker.new(valid_domain).check
    expect(checker.available).to be false
    expect(checker.error).to be_nil
  end

  it 'handles unsupported TLD ArgumentError' do
    allow(whois_client).to receive(:lookup).and_raise(ArgumentError.new('undefined group name reference'))
    checker = DomainChecker.new(unsupported_domain).check
    expect(checker.error).to match(/WHOIS server is not supported/)
    expect(checker.available).to be_nil
  end

  it 'handles generic errors' do
    allow(whois_client).to receive(:lookup).and_raise(StandardError.new('something went wrong'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.error).to match(/something went wrong/)
    expect(checker.available).to be_nil
  end

  it 'handles ArgumentError with a different message in check' do
    allow(Whois::Client).to receive(:new).and_return(whois_client)
    allow(whois_client).to receive(:lookup).with(valid_domain).and_raise(ArgumentError.new('some other error'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.error).to match(/Error checking domain: some other error/)
    expect(checker.available).to be_nil
  end

  it 'handles generic error in check' do
    allow(Whois::Client).to receive(:new).and_return(whois_client)
    allow(whois_client).to receive(:lookup).with(valid_domain).and_raise(StandardError.new('fail!'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.error).to match(/Error checking domain: fail!/)
    expect(checker.available).to be_nil
  end

  it 'generates suggestions and checks their availability' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    # For suggestions
    allow(whois_client).to receive(:lookup).with(/getexample/).and_return(double(parser: double(available?: true)))
    allow(whois_client).to receive(:lookup).with(/exampleapp/).and_return(double(parser: double(available?: false)))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.suggestions).to_not be_empty
    expect(checker.suggestion_results.values).to include(true, false)
  end

  it 'handles errors in suggestion lookups gracefully' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    allow(whois_client).to receive(:lookup).with(/getexample/).and_raise(ArgumentError.new('undefined group name reference'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.suggestion_results.values).to include(nil)
  end

  it 'sets suggestion result to nil on generic error' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    allow(whois_client).to receive(:lookup).with(/getexample/).and_raise(StandardError.new('fail!'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.suggestion_results.values).to include(nil)
  end

  it 'sets suggestion result to nil for ArgumentError without group name reference' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    allow(whois_client).to receive(:lookup).with('getexample.com').and_raise(ArgumentError.new('other error'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.suggestion_results['getexample.com']).to be_nil
  end

  it 'sets suggestion result to nil for generic error in generate_suggestions' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    allow(whois_client).to receive(:lookup).with('getexample.com').and_raise(StandardError.new('fail!'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.suggestion_results['getexample.com']).to be_nil
  end

  it 'sets suggestion result to nil for ArgumentError with group name reference' do
    allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
    allow(whois_record).to receive(:parser).and_return(whois_parser)
    allow(whois_parser).to receive(:available?).and_return(true)
    allow(whois_client).to receive(:lookup).with(/getexample/).and_raise(ArgumentError.new('undefined group name reference'))
    checker = DomainChecker.new(valid_domain).check
    expect(checker.suggestion_results.values).to include(nil)
  end
end
