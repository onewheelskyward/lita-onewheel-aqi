require 'spec_helper'
require 'timecop'

describe Lita::Handlers::OnewheelAqi, lita_handler: true do
  it { is_expected.to route_command('aqi') }
  it { is_expected.to route_command('aqidetails') }
  it { is_expected.to route_command('aqideets') }

  def mock(file)
    mock = File.open("spec/fixtures/#{file}.json").read
    allow(RestClient).to receive(:get) { mock }
  end

  before do
    Timecop.freeze Time.local(2017, 8, 11, 16, 0, 0)

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

    Geocoder::Lookup::Test.add_stub(
      'Beaverton', [{
        'formatted_address' => 'Beaverton, OR, USA',
        'geometry' => {
          'location' => {
            'lat' => 45.523452,
            'lng' => -122.976207,
            'address' => 'Beaverton, OR, USA',
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
    mock('Output')
    send_command 'aqi'
    expect(replies.last).to include("AQI for Portland, OR, USA, ⚠️ 08Moderate ⚠️ pm25: 0876  µg/m³(est): 23.99  pm10: 0340  updated 0860 minutes ago.  14(http://aqicn.org/city/usa/oregon/government-camp-multorpor-visibility/)")
  end

  it 'queries the aqideets' do
    mock('Output')
    send_command 'aqideets'
    expect(replies.last).to eq("AQI for Portland, OR, USA, ⚠️ 08Moderate ⚠️ humidity: 11%  pressure: 1014mb  pm25: 0876  µg/m³(est): 23.99  pm10: 0340  temp: 34.65C  updated 0860 minutes ago.  14(http://aqicn.org/city/usa/oregon/government-camp-multorpor-visibility/)")
  end

  it 'queries the aqi by location' do
    mock('Output')
    send_command 'aqi Beaverton'
    expect(replies.last).to include("AQI for Beaverton, OR, USA, ⚠️ 08Moderate ⚠️ pm25: 0876  µg/m³(est): 23.99  pm10: 0340  updated 0860 minutes ago.  14(http://aqicn.org/city/usa/oregon/government-camp-multorpor-visibility/)")
  end

  it 'queries the aqideets' do
    mock('Output')
    send_command 'aqideets Beaverton'
    expect(replies.last).to eq("AQI for Beaverton, OR, USA, ⚠️ 08Moderate ⚠️ humidity: 11%  pressure: 1014mb  pm25: 0876  µg/m³(est): 23.99  pm10: 0340  temp: 34.65C  updated 0860 minutes ago.  14(http://aqicn.org/city/usa/oregon/government-camp-multorpor-visibility/)")
  end

  it 'dehli' do
    mock('dehli')
    send_command 'aqi'
    expect(replies.last).to eq("AQI for Portland, OR, USA, 🚫☣🚫 13Hazardous 🚫☣🚫 pm25: 13641  µg/m³(est): 615.1  pm10: 13875  updated -127740 minutes ago.  14(http://aqicn.org/city/delhi/punjabi-bagh/)")
  end
end
