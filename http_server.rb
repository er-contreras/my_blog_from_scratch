require_relative 'rider'
require 'socket'
require 'uri'

class HttpServer
  HTML_CONTENT = File.read('index.html')

  def initialize
    @server = TCPServer.new('localhost', 3000)
  end

  def start
    loop do
      client = @server.accept
      handle_request(client)
      client.close
    end
  end

  private

  def handle_request(client)
    request = client.gets

    case request
    when %r{GET /}
      send_response(client, 200, HTML_CONTENT, 'text/html')
    when %r{POST /create_rider}
      process_post_request(client)
    else
      send_response(client, 404, 'Not Found', 'text/plain')
    end
  end

  def process_post_request(client)
    # Parsing form data from POST body
    post_body = parse_post_body(client)
    params = URI.decode_www_form(post_body).to_h
    name = params['name']
    age = params['age']

    # Creating a Rider instance with the submitted data
    rider = Rider.new(name, age)

    # Generating rider details HTML
    rider_details = '<html><body><h1>Rider Details</h1>' \
      "<p>Name: #{rider.name}</p>" \
      "<p>Age: #{rider.age}</p></body></html>"

    send_response(client, 200, rider_details, 'text/html')
  end

  def parse_post_body(client)
    headers = {}
    while (line = client.gets&.chomp)
      break if line.empty?

      parts = line.split(': ')
      headers[parts[0]] = parts[1] if parts.length == 2
    end

    content_length = headers['Content-Length'].to_i
    client.read(content_length)
  end

  def send_response(client, status, body, content_type)
    client.puts "HTTP/1.1 #{status}\r\n" \
                  "Content-Type: #{content_type}\r\n" \
                  "Content-Length: #{body.bytesize}\r\n" \
                  "Connection: close\r\n\r\n" \
                  "#{body}"
  end
end

server = HttpServer.new
server.start
