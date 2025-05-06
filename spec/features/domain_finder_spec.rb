require 'rails_helper'

RSpec.feature 'DomainFinder', type: :feature do
  scenario 'User visits the domain finder form' do
    visit '/domains/new'
    expect(page).to have_content('Find Available Domain Name')
    expect(page).to have_selector('form')
  end

  scenario 'User submits an invalid domain' do
    visit '/domains/new'
    fill_in 'Domain name (e.g. example.com):', with: 'invalid_domain'
    click_button 'Check Availability'
    expect(page).to have_content('Invalid domain format')
  end

  scenario 'User submits a valid and available domain' do
    allow_any_instance_of(Whois::Client).to receive(:lookup).and_return(double(parser: double(available?: true)))
    visit '/domains/new'
    fill_in 'Domain name (e.g. example.com):', with: 'example.com'
    click_button 'Check Availability'
    expect(page).to have_content('is available')
    expect(page).to have_link('Purchase')
  end

  scenario 'User submits a valid and taken domain' do
    allow_any_instance_of(Whois::Client).to receive(:lookup).and_return(double(parser: double(available?: false)))
    visit '/domains/new'
    fill_in 'Domain name (e.g. example.com):', with: 'taken.com'
    click_button 'Check Availability'
    expect(page).to have_content('is taken')
  end

  scenario 'User triggers an unsupported TLD error' do
    allow_any_instance_of(Whois::Client).to receive(:lookup).and_raise(ArgumentError.new('undefined group name reference'))
    visit '/domains/new'
    fill_in 'Domain name (e.g. example.com):', with: 'unsupported.tld'
    click_button 'Check Availability'
    expect(page).to have_content("WHOIS server is not supported")
  end
end
