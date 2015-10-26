require 'geocoder'
require 'rest-client'

module Lita
  module Handlers
    class OnewheelAqi < Handler
      config :api_key
      config :distance

      route /^aqi (.*)/i,
            :get_aqi,
            command: true,
            help: '!aqi [location] gives you available data for air quality (PM2.5) forecast and latest observation.'

      def get_aqi(response)
        loc = geo_lookup(response.matches[0][0])
        puts loc.inspect

        parameters = {
            latitude: loc[:lat],
            longitude: loc[:lng],
            api_key: config.api_key,
            format: 'application/json'
        }

        query_string = (parameters.map { |k, v| "#{k}=#{v}" }).join "&"
        forecast_response = RestClient.get('http://airnowapi.org/aq/forecast/latLong/?' + query_string)
        forecasted_aqi = JSON.parse(forecast_response)
        Lita.logger.debug 'Forecast response: ' + forecasted_aqi.inspect

        observed_response = RestClient.get('http://airnowapi.org/aq/observation/latLong/current/?' + query_string)
        observed_aqi = JSON.parse(observed_response)
        Lita.logger.debug 'Observed response: ' + observed_aqi.inspect

        if forecasted_aqi.nil? and observed_aqi.nil?
          response.reply "No AQI data for #{loc[:name]}."
          Lita.logger.info "No data found for #{response.matches[0][0]}"
          return
        end

        # [{"DateObserved":"2015-08-23 ","HourObserved":14,"LocalTimeZone":"PST","ReportingArea":"Portland","StateCode":"OR","Latitude":45.538,"Longitude":-122.656,"ParameterName":"O3","AQI":49,"Category":{"Number":1,"Name":"Good"}},{"DateObserved":"2015-08-23 ","HourObserved":14,"LocalTimeZone":"PST","ReportingArea":"Portland","StateCode":"OR","Latitude":45.538,"Longitude":-122.656,"ParameterName":"PM2.5","AQI":167,"Category":{"Number":4,"Name":"Unhealthy"}}]
        # todo: extract today's forecast, not tomorrow's.
        forecasted_aqi = extract_pmtwofive(forecasted_aqi)
        observed_aqi = extract_pmtwofive(observed_aqi)

        reply = "AQI for #{loc[:name]}, "
        unless forecasted_aqi == []
          reply += "Forecasted: #{(forecasted_aqi['ActionDay'] == 'true')? 'Action Day! ' : ''}#{forecasted_aqi['AQI']} #{forecasted_aqi['Category']['Name']}  "
        end
        unless observed_aqi == []
          reply += "Observed: #{observed_aqi['AQI']} #{observed_aqi['Category']['Name']} at #{observed_aqi['DateObserved']}#{observed_aqi['HourObserved']}00 hours."
        end
        response.reply reply
      end

      def extract_pmtwofive(aqi)
        returned_aqi = aqi
        aqi.each do |a|
          if a['ParameterName'] == 'PM2.5'
            returned_aqi = a
          end
        end
        returned_aqi
      end

      # Geographical stuffs
      # Now with less caching!
      def optimistic_geo_wrapper(query)
        geocoded = nil
        result = ::Geocoder.search(query)
        if result[0]
          geocoded = result[0].data
        end
        geocoded
      end

      def geo_lookup(query)
        geocoded = optimistic_geo_wrapper query

        if (query.nil? or query.empty?) and geocoded.nil?
          query = 'Portland, OR'
        end

        {name: geocoded['formatted_address'],
         lat: geocoded['geometry']['location']['lat'],
         lng: geocoded['geometry']['location']['lng']
        }
      end

    end

    Lita.register_handler(OnewheelAqi)
  end
end
