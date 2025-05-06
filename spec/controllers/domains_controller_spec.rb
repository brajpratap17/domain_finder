require 'rails_helper'

describe DomainsController, type: :controller do
  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #check' do
    let(:valid_domain) { 'example.com' }
    let(:invalid_domain) { 'invalid_domain' }
    let(:whois_client) { instance_double(Whois::Client) }
    let(:whois_record) { instance_double(Whois::Record) }
    let(:whois_parser) { double('Whois::Parser', available?: true) }

    before do
      allow(Whois::Client).to receive(:new).and_return(whois_client)
      allow(whois_client).to receive(:lookup).and_return(whois_record)
    end

    context 'with a valid and available domain' do
      before do
        allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
        allow(whois_record).to receive(:parser).and_return(whois_parser)
        allow(whois_parser).to receive(:available?).and_return(true)
      end

      it 'shows the domain as available' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:available)).to be true
        expect(response).to render_template(:new)
      end
    end

    context 'with a valid and taken domain' do
      before do
        allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
        allow(whois_record).to receive(:parser).and_return(whois_parser)
        allow(whois_parser).to receive(:available?).and_return(false)
      end

      it 'shows the domain as taken' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:available)).to be false
        expect(response).to render_template(:new)
      end
    end

    context 'with an invalid domain format' do
      it 'shows an error message' do
        post :check, params: { domain: invalid_domain }
        expect(assigns(:error)).to match(/Invalid domain format/)
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises ArgumentError for unsupported TLD' do
      before do
        allow(whois_client).to receive(:lookup).and_raise(ArgumentError.new('undefined group name reference'))
      end

      it "shows a user-friendly error" do
        post :check, params: { domain: valid_domain }
        expect(assigns(:error)).to match(/WHOIS server is not supported/)
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises a generic error' do
      before do
        allow(whois_client).to receive(:lookup).and_raise(StandardError.new('something went wrong'))
      end

      it "shows a generic error message" do
        post :check, params: { domain: valid_domain }
        expect(assigns(:error)).to match(/something went wrong/)
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises a generic error for suggestions' do
      before do
        allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
        allow(whois_record).to receive(:parser).and_return(whois_parser)
        allow(whois_parser).to receive(:available?).and_return(true)
        allow(whois_client).to receive(:lookup).with(/getexample/).and_raise(StandardError.new('fail!'))
      end

      it 'handles generic errors in suggestion lookup gracefully' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:suggestion_results).values).to include(nil)
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises ArgumentError without group name reference for suggestions' do
      before do
        allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
        allow(whois_record).to receive(:parser).and_return(whois_parser)
        allow(whois_parser).to receive(:available?).and_return(true)
        allow(whois_client).to receive(:lookup).with(/getexample/).and_raise(ArgumentError.new('other error'))
      end

      it 'handles other ArgumentError in suggestion lookup gracefully' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:suggestion_results).values).to include(nil)
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises ArgumentError with group name reference for suggestions' do
      before do
        allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
        allow(whois_record).to receive(:parser).and_return(whois_parser)
        allow(whois_parser).to receive(:available?).and_return(true)
        allow(whois_client).to receive(:lookup).with(/getexample/).and_raise(ArgumentError.new('undefined group name reference'))
      end

      it 'handles group name reference ArgumentError in suggestion lookup gracefully' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:suggestion_results).values).to include(nil)
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises ArgumentError with a different message' do
      before do
        allow(whois_client).to receive(:lookup) do |arg|
          if arg == valid_domain
            raise ArgumentError.new('some other error')
          else
            raise "Should not be called"
          end
        end
      end
      it 'sets a generic error message' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:error)).to match(/Error checking domain: some other error/)
        expect(assigns(:available)).to be_nil
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises a generic error' do
      before do
        allow(whois_client).to receive(:lookup) do |arg|
          if arg == valid_domain
            raise StandardError.new('fail!')
          else
            raise "Should not be called"
          end
        end
      end
      it 'sets a generic error message' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:error)).to match(/Error checking domain: fail!/)
        expect(assigns(:available)).to be_nil
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises ArgumentError with a different message for suggestions' do
      before do
        allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
        allow(whois_record).to receive(:parser).and_return(whois_parser)
        allow(whois_parser).to receive(:available?).and_return(true)
        allow(whois_client).to receive(:lookup).with('getexample.com').and_raise(ArgumentError.new('some other error'))
      end
      it 'sets suggestion result to nil' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:suggestion_results)['getexample.com']).to be_nil
        expect(response).to render_template(:new)
      end
    end

    context 'when whois raises a generic error for suggestions' do
      before do
        allow(whois_client).to receive(:lookup).with(valid_domain).and_return(whois_record)
        allow(whois_record).to receive(:parser).and_return(whois_parser)
        allow(whois_parser).to receive(:available?).and_return(true)
        allow(whois_client).to receive(:lookup).with('getexample.com').and_raise(StandardError.new('fail!'))
      end
      it 'sets suggestion result to nil' do
        post :check, params: { domain: valid_domain }
        expect(assigns(:suggestion_results)['getexample.com']).to be_nil
        expect(response).to render_template(:new)
      end
    end

    describe 'POST #check for blank and invalid domain' do
      it 'renders new with error for blank domain' do
        post :check, params: { domain: '' }
        expect(assigns(:error)).to eq('Please enter a domain name.')
        expect(assigns(:available)).to be_nil
        expect(response).to render_template(:new)
      end

      it 'renders new with error for invalid domain' do
        post :check, params: { domain: 'bad_domain' }
        expect(assigns(:error)).to eq('Invalid domain format. Please enter a domain like example.com.')
        expect(assigns(:available)).to be_nil
        expect(response).to render_template(:new)
      end
    end
  end
end
