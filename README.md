# lita-onewheel-aqi

[![Build Status](https://travis-ci.org/onewheelskyward/lita-onewheel-aqi.svg?branch=master)](https://travis-ci.org/onewheelskyward/lita-onewheel-aqi)
[![Coverage Status](https://coveralls.io/repos/github/onewheelskyward/lita-onewheel-aqi/badge.svg?branch=master)](https://coveralls.io/github/onewheelskyward/lita-onewheel-aqi?branch=master)

I built this on a plane on day where wildfire smoke had caused Portland, OR's air quality to be worse than Hong Kong's.
The next year, I upgraded it to use a newer, better API.

http://airnowapi.org/aq101

http://aqicn.org/city/usa/oregon/portland

# Installation

Add lita-onewheel-aqi to your Lita instance's Gemfile:

`gem 'lita-onewheel-aqi'`

# Configuration

Add your API key to your lita_config.rb:

`config.handlers.onewheel_aqi.api_key`

It can be procured here: http://aqicn.org/api/

If you're using this in slack, turn off the IRC color codes by using:

`config.handlers.onewheel_aqi.colors = false`

# Usage

bot: aqi Portland, OR

^^ should return your PM2.5 number.

