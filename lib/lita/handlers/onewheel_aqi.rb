require 'geocoder'
require 'rest-client'

module Lita
  module Handlers
    class OnewheelAqi < Handler
      config :api_key

      route /^aqi (.*)/i, :get_aqi, command: true

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
        forecasted_aqi = JSON.parse(forecast_response)[0]
        observed_response = RestClient.get('http://airnowapi.org/aq/observation/latLong/current/?' + query_string)
        observed_aqi = JSON.parse(observed_response)

        puts forecasted_aqi.inspect
        if forecasted_aqi.nil? or observed_aqi.nil?
          response.reply "No AQI data for #{loc[:name]}."
          Lita.logger.info "No data found for #{response.matches[0][0]}"
          return
        end

        # [{"DateObserved":"2015-08-23 ","HourObserved":14,"LocalTimeZone":"PST","ReportingArea":"Portland","StateCode":"OR","Latitude":45.538,"Longitude":-122.656,"ParameterName":"O3","AQI":49,"Category":{"Number":1,"Name":"Good"}},{"DateObserved":"2015-08-23 ","HourObserved":14,"LocalTimeZone":"PST","ReportingArea":"Portland","StateCode":"OR","Latitude":45.538,"Longitude":-122.656,"ParameterName":"PM2.5","AQI":167,"Category":{"Number":4,"Name":"Unhealthy"}}]
        observed_aqi.each do |o|
          if (o["ParameterName"] == "PM2.5")
            observed_aqi = o
          end
        end
        response.reply "AQI for #{loc[:name]}, Forecasted: #{forecasted_aqi["AQI"]} #{forecasted_aqi["Category"]["Name"]} -- Observed: #{observed_aqi["AQI"]} #{observed_aqi["Category"]["Name"]}"
      end

      # Geographical stuffs
      # Now with less caching!
      def optimistic_geo_wrapper(query)
        geocoded = nil
        result = ::Geocoder.search(query)
        # Lita.logger.debug "Geocoder result: '#{result.inspect}'"
        if result[0]
          geocoded = result[0].data
        end
        geocoded
      end

      def geo_lookup(query)
        if (query.nil? or query.empty?) and geocoded.nil?
          query = 'Portland, OR'
        end

        geocoded = optimistic_geo_wrapper query

        loc = {name: geocoded['formatted_address'],
            lat: geocoded['geometry']['location']['lat'],
            lng: geocoded['geometry']['location']['lng']
        }

        # Lita.logger.debug "loc: '#{loc}'"

        loc
      end

    end

    Lita.register_handler(OnewheelAqi)
  end
end
