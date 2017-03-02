## Service discovery by BGP communities

* Parse incoming BGP community `<AS>:<port>`;
* Generate hash of arrays of IP addresses by port as a key;
* Generate custom template reusing `services` hash.

#### Usage

* gem install exa-template

```
require 'exa-template'

ExaTemplate.new('/etc/exa-template/service.cfg.erb',
                '/etc/servicex/service.cfg').parse_events
```

#### Hash example

```
services = {
  '443' => ['2001:802::123/128', '1.1.1.1/32'],
  '8080' => ['1.1.1.1/32']
}
```

#### Template example

```
<% services.each do |port, ips| %>
service_<%= port %>
  listen 127.0.0.1:<%= port %>
  <%- ips.each do |ip| -%>
  backend <%= ip.split('/')[0] %>:<%= port %>
  <%- end -%>
<% end %>
```
