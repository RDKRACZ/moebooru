require_relative 'boot'

# To allow setting environment variable ZP_DATABASE_URL instead of DATABASE_URL.
ENV['DATABASE_URL'] = ENV['MB_DATABASE_URL'] if ENV['MB_DATABASE_URL']
ENV['NODE_ENV'] = ENV['RAILS_ENV']

require 'rails/all'

require_relative 'init_config'

Bundler.require(*CONFIG['bundler_groups'])

module Moebooru
  class Application < Rails::Application
    config.load_defaults 7.0
    config.active_record.belongs_to_required_by_default = false
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Also load files in lib/ in addition to app/.
    config.eager_load_paths << Rails.root.join('lib')

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.available_locales = CONFIG["available_locales"]
    config.i18n.default_locale = CONFIG["default_locale"]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    if CONFIG["memcache_servers"]
      config.cache_store = :mem_cache_store, CONFIG["memcache_servers"], {
        :namespace => CONFIG["app_name"],
        :pool_size => CONFIG["threads"],
        :value_max_bytes => 2_000_000
      }
    end

    # This one is never reliable because there's no standard controlling this.
    config.action_dispatch.ip_spoofing_check = false

    config.action_controller.asset_host = CONFIG[:file_hosts][:assets] if CONFIG[:file_hosts]
    config.action_mailer.default_url_options = { :host => CONFIG["server_host"] }

    config.ssl_options = { hsts: false }

    config.middleware.delete ActionDispatch::HostAuthorization
  end
end
