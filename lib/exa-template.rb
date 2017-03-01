require 'erb'
require 'json'

class ExaTemplate
  def initialize(template, destination, route_refresh = 5)
    @template = template
    @destination = destination
    @bindings = binding
    @services = reset_services
    @route_refresh = route_refresh
  end

  def parse_events
    loop do
      chunks = []
      begin
        loop do
          chunks << STDIN.read_nonblock(4096)
        end
      rescue IO::WaitReadable
        retry if IO.select([STDIN], [], [], @route_refresh)
        chunks.join.chomp.split("\n").each do |line|
          event = JSON.parse(line)
          next unless event['type'] == 'update'

          parse_services(event)
          @bindings.local_variable_set(:services, @services)
          render_template
        end
        route_refresh
      end
    end
  end

  private

  def reset_services
    @services = Hash.new { |h,k| h[k] = [] }
  end

  def route_refresh
    reset_services
    $stdout.write 'announce route-refresh ipv4 unicast'
    $stdout.write 'announce route-refresh ipv6 unicast'
    $stdout.flush
  end

  def parse_services(event)
    community = event['neighbor']['message']['update']['attribute']['community']
    community&.each do |c|
      port = c[1]
      event['neighbor']['message']['update']['announce']['ipv4 unicast']&.each do |_, prefix|
        @services[port] << prefix.keys.flatten.first
      end
      event['neighbor']['message']['update']['announce']['ipv6 unicast']&.each do |_, prefix|
        @services[port] << prefix.keys.flatten.first
      end
    end
  end

  def render_template
    template = ERB.new(File.read(@template), nil, '-').result(@bindings)
    File.write(@destination, template)
  end
end