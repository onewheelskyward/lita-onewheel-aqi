require 'geocoder'
require 'rest-client'

module Lita
  module Handlers
    class OnewheelAqi < Handler
      config :api_key
      config :distance
      config :colors, default: true

      route /^aqi\s+(.*)$/i,
            :get_aqi,
            command: true,
            help: { '!aqi [location]' => 'Gives you available data for air quality (PM2.5) forecast and latest observation.' }
      route /^aqi$/i,
            :get_aqi,
            command: true
      route /^aqi(deets|details)\s*(.*)$/i,
            :get_aqi_deets,
            command: true,
            help: { '!aqideets [location]' => 'Gives you moar datas.' }

      # IRC colors.
      def colors
        { white:  '00',
          black:  '01',
          blue:   '02',
          green:  '03',
          red:    '04',
          brown:  '05',
          purple: '06',
          orange: '07',
          yellow: '08',
          lime:   '09',
          teal:   '10',
          aqua:   '11',
          royal:  '12',
          pink:   '13',
          grey:   '14',
          silver: '15' }
      end

      # Based on the temp in F.
      def aqi_range_colors
        { 0..50 => :green,
          51..100 => :yellow,
          101..150 => :orange,
          151..200 => :red,
          201..300 => :purple,
          301..500 => :pink }
      end

      def get_location(response)
        location = response.matches[0][0].to_s.strip
        puts "'#{location}'"
        location = 'Portland, OR' if location.empty?

        loc = geo_lookup(location)
        puts loc.inspect
        loc
      end

      def get_observed_aqi(loc)
        uri = "http://api.waqi.info/feed/geo:#{loc[:lat]};#{loc[:lng]}/?token=#{config.api_key}"
        Lita.logger.debug "Getting aqi from #{uri}"

        observed_response = RestClient.get(uri)
        observed_aqi = JSON.parse(observed_response)
        Lita.logger.debug 'Observed response: ' + observed_aqi.inspect
        observed_aqi
      end

      def get_aqi(response)
        loc = get_location(response)
        observed_aqi = get_observed_aqi(loc)
        observed_pm25 = extract_pmtwofive(observed_aqi)

        reply = "AQI for #{loc[:name]}, "
        # unless forecasted_aqi == []
        #   reply += "Forecasted: #{(forecasted_aqi['ActionDay'] == 'true')? 'Action Day! ' : ''}#{forecasted_aqi['AQI']} #{forecasted_aqi['Category']['Name']}  "
        # end

        banner_str = "(#{observed_aqi['data']['city']['url']})"
        if config.colors
          banner_str = "\x03#{colors[:grey]}#{banner_str}\x03"
        end

        unless observed_aqi == []
          reply += "Observed PM25: #{color_str(observed_pm25)}  #{banner_str}"
        end
        response.reply reply
      end

      def color_str(str)

        if config.colors
          aqi_range_colors.keys.each do |color_key|
            if color_key.cover? str.to_i    # Super secred cover sauce
              color = colors[aqi_range_colors[color_key]]
              str = "\x03#{color}#{str}\x03"
            end
          end
        end

        str
      end

      def extract_pmtwofive(aqi)
        Lita.logger.debug "extract_pmtwofive with #{aqi}"
        pm25 = ''
        if aqi['data']['iaqi']['pm25']
          pm25 = aqi['data']['iaqi']['pm25']['v']
        else
          pm25 = "No PM2.5 data for #{aqi['data']['city']['name']}"
        end
        pm25
      end

      # Geographical stuffs
      # Now with less caching!
      def optimistic_geo_wrapper(query)
        geocoded = nil
        result = ::Geocoder.search(query)
        puts result.inspect
        geocoded = result[0].data if result[0]
        geocoded
      end

      def geo_lookup(query)
        puts "Location lookup #{query.inspect}"
        geocoded = optimistic_geo_wrapper query

        query = 'Portland, OR' if (query.nil? || query.empty?) && geocoded.nil?

        { name: geocoded['formatted_address'],
          lat: geocoded['geometry']['location']['lat'],
          lng: geocoded['geometry']['location']['lng'] }
      end
    end

    Lita.register_handler(OnewheelAqi)
  end
end
