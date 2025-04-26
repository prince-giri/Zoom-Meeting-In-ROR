require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'jwt'
module ZoomMeetingService2
  class ZoomMeetingService
    def self.get_access_token
      uri = URI.parse('https://zoom.us/oauth/token')
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(ENV['ZOOM_CLIENT_ID'], ENV['ZOOM_CLIENT_SECRET_ID'])

      request.set_form_data(
        'grant_type' => 'account_credentials',
        'account_id' => ENV['ZOOM_ACCOUNT_ID']
      )

      req_options = {
        use_ssl: uri.scheme == 'https',
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      JSON.parse(response.body)['access_token']
    end

    def self.create_meeting(meeting_params, quote, notary_request)
      access_token = get_access_token
      uri = URI.parse('https://api.zoom.us/v2/users/me/meetings')
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'
      request.body = meeting_params.to_json
      req_options = { use_ssl: uri.scheme == 'https' }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if ["200", "201"].include?(response.code)
        meeting_data = JSON.parse(response.body)
        zoom_meeting = BxBlockCfzoomintegration92::ZoomMeeting.create(
          meeting: meeting_data,
          notary_request_id: notary_request[:notary_request].id,
          start_time: quote.start_time,
          end_time: quote.end_time
        )
        return zoom_meeting
      end
      nil
    end
  end
end
