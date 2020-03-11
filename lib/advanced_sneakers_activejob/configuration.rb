# frozen_string_literal: true

module AdvancedSneakersActiveJob
  # Advanced Sneakers adapter allows to patch Sneakers with custom configuration.
  # It is useful when already have Sneakers workers running and you want to run ActiveJob Sneakers process with another options.
  class Configuration
    include ActiveSupport::Configurable

    config_accessor(:safe_publish) { true } # creates queue & bindings before publish
    config_accessor(:bind_by_queue_name) { true } # creates binding by queue name even if routing key differs
    config_accessor(:activejob_workers_strategy) { :include } # [:include, :exclude, :only]

    def sneakers
      config.sneakers || Sneakers::CONFIG
    end

    def sneakers=(custom)
      config.sneakers = custom
    end
  end
end