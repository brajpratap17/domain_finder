require 'rails_helper'

describe ApplicationMailer do
  it 'inherits from ActionMailer::Base' do
    expect(ApplicationMailer.superclass).to eq(ActionMailer::Base)
  end
end
