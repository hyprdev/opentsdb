# Opentsdb

Opentsdb is Ruby adapter to access time series database using it's REST API.

## Basic usage
You can connect to Opentsdb simply by writing
```ruby
require 'opentsdb'

opentsdb = Opentsdb::Client.new
```
Default options assume you connect to localhost and default port 4242. You can pass options as hash:
``` ruby
opentsdb = Opentsdb::Client.new host: '10.0.0.2', port: 2345
```
or use block to set options:
```ruby
Opentsdb.configure do |config|
  config.host = '10.0.0.2'
  config.port = 2345
end
```

The following is the full list of available configuration options:
```ruby
host                         # database hostname default: "127.0.0.1"
port                          # database port default: 4242
type                         # response type for queries default: details
timezone                 # timezone to use in queries default: UTC
logger                      # logger used for profiling
```
### Reading data
To query some information from database you need to use query method:
```ruby
  results = opentsdb.query({
    start: 1511741194,
    end: 1519223824,
    queries: [{
      aggregator: "sum",
      metric: "host.cpu",
      tags: {
        host: "*",
        dc: "lga"
      }
    }]
  })
```

### Writing data
Writing single datapoint into database:
```ruby
  results = opentsdb.put({
    metric: "sys.cpu.nice",
    timestamp: 1346846400,
    value: 18,
    tags: {
      host: "web01",
      dc: "lga"
    }
  })
```

you can pass Array to write multiple datapoints:
```ruby
  results = opentsdb.put([
    {
      metric: "sys.cpu.nice",
      timestamp: 1346846400,
      value: 18,
      tags: {
        host: "web01",
        dc: "lga"
      }
    },
    {
      metric: "sys.cpu.nice",
      timestamp: 1346846500,
      value: 13,
      tags: {
        host: "web01",
        dc: "lga"
      }
    },
  ])
```

## Testing
This project using RSpec for running tests. You can run all tests by doing
```
bundle install rspec
rspec
```