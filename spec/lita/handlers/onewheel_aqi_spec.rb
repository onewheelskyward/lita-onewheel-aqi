require "spec_helper"

describe Lita::Handlers::OnewheelAqi, lita_handler: true do
  it { is_expected.to route_command('aqi') }
end
