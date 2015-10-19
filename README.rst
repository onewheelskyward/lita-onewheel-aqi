lita-onewheel-aqi
=================

.. image:: https://coveralls.io/repos/onewheelskyward/lita-onewheel-aqi/badge.svg?branch=master&service=github :target: https://coveralls.io/github/onewheelskyward/lita-onewheel-aqi?branch=master
.. image:: https://travis-ci.org/onewheelskyward/lita-onewheel-aqi.svg?branch=master :target: https://travis-ci.org/onewheelskyward/lita-onewheel-aqi

I built this on a plane on day where wildfire smoke had caused Portland, OR's air quality to be worse than Hong Kong's.
The data is a little spotty, but it worked good enough for an hour at the stick.

http://airnowapi.org/aq101

http://airnowapi.org/webservices

http://airnowapi.org/forecastsbylatlon/docs

Installation
============
Add lita-onewheel-aqi to your Lita instance's Gemfile:

``` ruby
gem 'lita-onewheel-aqi'
```

Configuration
=============

Add your API key to your lita_config.rb:

`config.handlers.onewheel_aqi.api_key`

It can be procured here: http://airnowapi.org/account/request/

Usage
=====

bot: aqi Portland, OR

^^ should return your PM2.5 number.

