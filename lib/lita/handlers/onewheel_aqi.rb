require 'geocoder'
require 'rest-client'

module Lita
  module Handlers
    class OnewheelAqi < Handler
      config :api_key
      config :distance
      config :mode, default: :irc

      route /^aqi\s+(.*)$/i,
            :get_aqi,
            command: true,
            help: { '!aqi [location]' => 'Gives you available data for air quality (PM2.5) forecast and latest observation.' }
      route /^aqi$/i,
            :get_aqi,
            command: true
      route /^aqideets\s*(.*)$/i,
            :get_aqi_deets,
            command: true,
            help: { '!aqideets [location]' => 'Gives you moar datas.' }
      route /^aqidetails\s*(.*)$/i,
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

      def aqi_range_labels
        { 0..50 => 'Good',
          51..100 => 'Moderate',
          101..150 => 'Unhealthy for Sensitive Groups',
          151..200 => 'Unhealthy for All',
          201..300 => 'Very Unhealthy',
          301..500 => 'Hazardous' }
      end

      def aqi_slack_emoji
        { 0..50 => ':deciduous_tree:',
          51..100 => ':warning:',
          101..150 => ':large_orange_diamond:',
          151..200 => ':no_entry_sign:',
          201..300 => ':radioactive_sign:',
          301..500 => ':no_entry_sign: :radioactive_sign: :no_entry_sign:' }
      end

      def aqi_irc_emoji
        { 0..50 => '🌳',
          51..100 => '⚠️',
          101..150 => '🔶',
          151..200 => '🚫',
          201..300 => '☣️',
          301..500 => '🚫☣🚫' }
      end

      def get_location(response)
        location = if response.matches[0][0].to_s.length == 1
                     ''
                   else
                     response.matches[0][0]
                   end

        puts "get_location: '#{location}'"
        location = 'Portland, OR' if location.nil? || location.empty?

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
        aqi = get_observed_aqi(loc)

        banner_str = "(#{aqi['data']['city']['url']})"

        reply = "AQI for #{loc[:name]}, "

        Lita.logger.debug "Config mode: #{config.mode.inspect}"

        if config.mode == :irc
          reply += color_str_with_value(range_str: aqi_range_labels, range_value: aqi['data']['iaqi']['pm25']['v'].to_s)
          banner_str = "\x03#{colors[:grey]}#{banner_str}\x03"
        elsif config.mode == :slack
          reply += color_str_with_value(range_str: aqi_range_labels, range_value: aqi['data']['iaqi']['pm25']['v'].to_s)
        end

        if aqi['data']['iaqi']['pm25']
          reply += 'pm25: ' + color_str(aqi['data']['iaqi']['pm25']['v'].to_s) + '  '
          ugm3 = pm25_to_ugm3 aqi['data']['iaqi']['pm25']['v'].to_s
          reply += "#{ugm3} µgm3(est)  "
        end
        if aqi['data']['iaqi']['pm10']
          reply += 'pm10: ' + color_str(aqi['data']['iaqi']['pm10']['v'].to_s) + '  '
        end

        updated_at = Time.parse aqi['data']['time']['s']
        diff = (Time.now - updated_at).to_i / 60

        reply += "updated #{color_str(diff.to_s)} minutes ago.  #{banner_str}"

        response.reply reply
      end

      def get_aqi_deets(response)
        loc = get_location(response)
        aqi = get_observed_aqi(loc)

        reply = "AQI for #{loc[:name]}, "

        banner_str = "(#{aqi['data']['city']['url']})"

        if config.mode == :irc
          reply += color_str_with_value(range_str: aqi_range_labels, range_value: aqi['data']['iaqi']['pm25']['v'].to_s)
          banner_str = "\x03#{colors[:grey]}#{banner_str}\x03"
        end

        if aqi['data']['iaqi']['co']
          reply += 'co: ' + aqi['data']['iaqi']['co']['v'].to_s + '  '
        end
        if aqi['data']['iaqi']['h']
          reply += 'humidity: ' + aqi['data']['iaqi']['h']['v'].to_s + '%  '
        end
        if aqi['data']['iaqi']['p']
          reply += 'pressure: ' + aqi['data']['iaqi']['p']['v'].to_s + 'mb  '
        end
        if aqi['data']['iaqi']['pm25']
          reply += 'pm25: ' + color_str(aqi['data']['iaqi']['pm25']['v'].to_s) + '  '
          ugm3 = pm25_to_ugm3 aqi['data']['iaqi']['pm25']['v']
          reply += "#{ugm3} µgm3(est)  "
        end
        if aqi['data']['iaqi']['pm10']
          reply += 'pm10: ' + color_str(aqi['data']['iaqi']['pm10']['v'].to_s) + '  '
        end
        if aqi['data']['iaqi']['t']
          reply += 'temp: ' + aqi['data']['iaqi']['t']['v'].to_s + 'C  '
        end

        updated_at = Time.parse aqi['data']['time']['s']
        diff = (Time.now - updated_at).to_i / 60

        reply += "updated #{color_str(diff.to_s)} minutes ago.  #{banner_str}"
        response.reply reply
      end

      def color_str(str, value = nil)
        value = str.to_i if value.nil?

        aqi_range_colors.keys.each do |color_key|
          next unless color_key.cover? value # Super secred cover sauce
          if config.mode == :irc
            color = colors[aqi_range_colors[color_key]]
            str = "\x03#{color}#{str}\x03"
          end
        end

        str
      end

      def color_str_with_value(range_str:, range_value:)
        str = nil
        aqi_range_colors.keys.each do |color_key|
          next unless color_key.cover? range_value.to_i # Super secred cover sauce
          color = colors[aqi_range_colors[color_key]]
          if config.mode == :irc
            str = "#{aqi_irc_emoji[color_key]} \x03#{color}#{range_str[color_key]}\x03 #{aqi_irc_emoji[color_key]} "
          elsif config.mode == :slack
            str = "#{aqi_slack_emoji[color_key]} #{range_str[color_key]} #{aqi_slack_emoji[color_key]} "
          end
        end

        str
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

      # Particulate Matter 2.5 to micrograms per cubic meter
      def pm25_to_ugm3(pm25)
        ranges = {
          0..50 => [0, 50, 0.0, 12.0],
          51..100 => [51, 100, 12.1, 35.4],
          101..150 => [101, 150, 35.5, 55.4],
          151..200 => [151, 200, 55.5, 150.4],
          201..300 => [201, 300, 150.5, 250.4],
          301..500 => [301, 500, 250.5, 500]
        }
        ranges.keys.each do |range_key|
          next unless range_key.cover? pm25.to_i
          low = ranges[range_key][0]
          high = ranges[range_key][1]
          min = ranges[range_key][2]
          max = ranges[range_key][3]
          step = (max - min) / (high - low)
          ugm3 = (pm25.to_i - low) * step + min
          return ugm3.round(2)
        end
      end
    end

    Lita.register_handler(OnewheelAqi)
  end
end
