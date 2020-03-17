# frozen_string_literal: true

module AdvancedSneakersActiveJob
  # Advanced Sneakers adapter allows to patch Sneakers with custom configuration.
  # It is useful when already have Sneakers workers running and you want to run ActiveJob Sneakers process with another options.
  class Configuration
    include ActiveSupport::Configurable

    config_accessor(:handle_unrouted_messages) { true } # create queue/binding and re-publish if message is unrouted
    config_accessor(:activejob_workers_strategy) { :include } # [:include, :exclude, :only]

    def sneakers
      Sneakers::CONFIG.to_hash.deep_merge(config.sneakers || {}).merge(log: ActiveJob::Base.logger)
    end

    def sneakers=(custom)
      config.sneakers = custom
    end
  end
end
