require 'rails_helper'

describe ApplicationRecord do
  it 'is an abstract class' do
    expect(ApplicationRecord.abstract_class).to be true
  end
end
