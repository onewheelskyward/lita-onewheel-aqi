require 'spec_helper'

describe Lita::Handlers::OnewheelAqi, lita_handler: true do
  it { is_expected.to route_command('aqi') }
  it { is_expected.to route_command('aqidetails') }
  it { is_expected.to route_command('aqideets') }

  before do
    mock = File.open('spec/fixtures/Output.json').read
    allow(RestClient).to receive(:get) { mock }

    Geocoder.configure(lookup: :test)

    Geocoder::Lookup::Test.add_stub(
      'Portland, OR', [{
        'formatted_address' => 'Portland, OR, USA',
        'geometry' => {
          'location' => {
            'lat' => 45.523452,
            'lng' => -122.676207,
            'address' => 'Portland, OR, USA',
            'state' => 'Oregon',
            'state_code' => 'OR',
            'country' => 'United States',
            'country_code' => 'US'
          }
        }
      }]
    )
  end

  it 'queries the aqi' do
    send_command 'aqi'
    expect(replies.last).to include("AQI for Portland, OR, USA, Observed PM25: \u00030876\u0003  \u000314(http://aqicn.org/city/usa/oregon/government-camp-multorpor-visibility/)\u0003")
  end
end
