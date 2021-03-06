require 'hipchat'
require 'spec_helper'

describe Service::HipChat do
  let(:config) do
    {
      :api_token => 'token',
      :room => 'room id',
      :notify => nil
    }
  end

  it 'has a title' do
    expect(Service::HipChat.title).to eq('HipChat')
  end

  describe 'schema and display configuration' do
    subject { Service::HipChat }

    it { is_expected.to include_string_field :api_token }
    it { is_expected.to include_checkbox_field :v2 }
    it { is_expected.to include_string_field :room }
    it { is_expected.to include_checkbox_field :notify }
    it { is_expected.to include_string_field :url }

    it { is_expected.to include_page 'API Token', [:api_token, :v2] }
    it { is_expected.to include_page 'Room', [:room, :notify] }
    it { is_expected.to include_page 'URL', [:url] }
  end

  describe :receive_verification do
    it :success do
      service = Service::HipChat.new('verification', {})
      expect(service).to receive(:receive_verification_message)
      expect(service).to receive(:send_message)

      success, message = service.receive_verification(config, nil)
      expect(success).to be true
    end

    it :failure do
      service = Service::HipChat.new('verification', {})
      expect(service).to receive(:receive_verification_message)
      expect(service).to receive(:send_message).and_raise

      success, message = service.receive_verification(config, nil)
      expect(success).to be false
    end
  end

  describe :receive_issue_impact_change do
    it do
      payload = { :url => 'url', :app => { :name => 'name' }, 
                  :title => 'title', :method => 'method' }
      service = Service::HipChat.new('issue_impact_change', {})
      expect(service).to receive(:format_issue_impact_change_message).with(payload)
      expect(service).to receive(:send_message)

      expect(service.receive_issue_impact_change(config, payload)).to eq(:no_resource)
    end

    it 'surfaces exceptions as runtime errors' do
      payload = { :url => 'url', :app => { :name => 'name' },
            :title => 'title', :method => 'method' }
      service = Service::HipChat.new('issue_impact_change', {})

      expect(service).to receive(:send_message).and_raise('Unhandled error')

      expect {
        service.receive_issue_impact_change(config, payload)
      }.to raise_error(/Unhandled error/)
    end
  end

  describe :send_message do
    it do
      message = 'hi'
      client = double(HipChat::Client)
      options = { :api_version => 'v1' }
      expect(HipChat::Client).to receive(:new).with(config[:api_token], options).and_return(client)
      expect(client).to receive(:[]).with(config[:room]).and_return(client)
      expect(client).to receive(:send).with('Crashlytics', message, { :notify => false })

      Service::HipChat.new('verification', {}).send(:send_message, config, message)
    end
  end
end
