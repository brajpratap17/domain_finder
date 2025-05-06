require 'rails_helper'

describe ApplicationJob do
  it 'inherits from ActiveJob::Base' do
    expect(ApplicationJob.superclass).to eq(ActiveJob::Base)
  end
end
