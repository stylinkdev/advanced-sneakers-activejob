# frozen_string_literal: true

module AdvancedSneakersActiveJob
  # Rails integration
  class Railtie < ::Rails::Railtie
    initializer 'advanced_sneakers_activejob.discover_mailer_job' do
      ActiveSupport.on_load(:action_mailer) do
        require 'action_mailer/delivery_job' # Enforce definition of ActionMailer::DeliveryJob::Consumer
      end
    end

    rake_tasks do
      require 'advanced_sneakers_activejob/tasks'
    end
  end
end