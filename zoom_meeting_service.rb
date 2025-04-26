require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'jwt'

module ZoomMeeting
  class ZoomVideoService
    def initialize(api_key = ENV['ZOOM_API_KEY'], api_secret = ENV['ZOOM_API_SECRET'])
      @api_key = api_key
      @api_secret = api_secret
    end

    def create_session(session_params, quote, notary_request)
      uri = URI.parse("https://api.zoom.us/v2/videosdk/sessions")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request["Authorization"] = "Bearer #{generate_jwt_token}"

      request.body = JSON.dump(session_params.merge({
        global_dial_in_countries: ["US"],
        global_dial_in_numbers: [
          {
            country: "US",
            country_name: "US",
            number: "+1 1000200200",
            type: "toll"
          }
        ]
      }))

      req_options = {
        use_ssl: uri.scheme == "https",
        verify_mode: OpenSSL::SSL::VERIFY_PEER
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if ["200", "201"].include?(response.code)
        meeting_data = JSON.parse(response.body)
        zoom_meeting = ZoomMeeting::ZoomMeeting.create(
          meeting: meeting_data,
          notary_request_id: notary_request[:notary_request].id,
          start_time: quote.start_time,
          end_time: quote.end_time
        )
        return zoom_meeting
      end
      nil
    end

    private

    def generate_jwt_token
      payload = {
        iss: @api_key,
        exp: (Time.now.to_i + 24 * 3600)
      }
      JWT.encode(payload, @api_secret, 'HS256')
    end
  end
end