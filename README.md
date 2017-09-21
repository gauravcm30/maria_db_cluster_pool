# Database Cluster [![Build Status](https://travis-ci.org/renemadsen/maria_db_cluster_pool.png)](https://travis-ci.org/renemadsen/maria_db_cluster_pool)

MariaDB Cluster Pool gem is designed for usage with Maria DB Galera Cluster, so this gem will only support a master/master setup

# Configuration

## The pool configuration

The cluster connections are configured in database.yml using the maria_db_cluster_pool adapter. Any properties you configure for the connection will be inherited by all connections in the pool. In this way, you can configure ports, usernames, etc. once instead of for each connection. One exception is that you can set the pool_adapter property which each connection will inherit as the adapter property. Each connection in the pool uses all the same configuration properties as normal for the adapters.

### Example configuration

```ruby
  development:
      adapter: maria_db_cluster_pool
      database: mydb_development
      username: read_user
      password: abc123
      pool_adapter: mysql
      port: 3306
      encoding: utf8
      server_pool:
        - host: read-db-1.example.com
          pool_weight: 1
        - host: read-db-2.example.com
          pool_weight: 2
```

## Rails 2.3.x

To make rake db:migrate, rake db:seed work, remember to put:

```ruby
  config.gem 'maria_db_cluster_pool'
```

in the environment.rb

## Known issues:

```ruby
  rake db:test:clone
```

will not work.

## Credits

This software is a derived work of https://github.com/renemadsen/maria_db_cluster_pool the parts which derives from that codes is copyrighted by René Schultz Madsen
