# frozen_string_literal: true

module AdvancedSneakersActiveJob
  # Sneakers uses Sneakers::Worker::Classes array to track all workers.
  # WorkersRegistry mocks original array to track ActiveJob workers separately.
  class WorkersRegistry
    attr_reader :sneakers_workers

    delegate :activejob_workers_strategy, to: :'AdvancedSneakersActiveJob.config'

    delegate :empty?, to: :call

    def initialize
      @sneakers_workers = []
      @activejob_workers = []
    end

    def <<(worker)
      if worker <= ActiveJob::QueueAdapters::AdvancedSneakersAdapter::JobWrapper
        @activejob_workers << worker
      else
        sneakers_workers << worker
      end
    end

    # Sneakers workergroup supports callable objects.
    # https://github.com/jondot/sneakers/pull/210/files
    # https://github.com/jondot/sneakers/blob/7a972d22a58de8a261a738d9a1e5fb51f9608ede/lib/sneakers/workergroup.rb#L28
    def call
      case activejob_workers_strategy
      when :only    then activejob_workers
      when :exclude then sneakers_workers
      when :include then sneakers_workers + activejob_workers
      else
        raise "Unknown activejob_workers_strategy '#{activejob_workers_strategy}'"
      end
    end

    def to_hash
      {
        sneakers_workers: sneakers_workers,
        activejob_workers: activejob_workers
      }
    end

    alias to_h to_hash

    # For cleaner output on inspecting Sneakers::Worker::Classes in console.
    alias inspect to_hash

    def activejob_workers
      define_active_job_consumers
      if ActionMailer.gem_version >= Gem::Version.new("7.1.0")
        define_action_mailer_consumers
      end

      @activejob_workers
    end

    def method_missing(method_name, *, &block)
      if call.respond_to?(method_name)
        call.send(method_name, *, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      call.respond_to?(method_name) || super
    end

    def define_active_job_consumers
      active_job_classes_with_matching_adapter.each do |worker|
        # after upgrading to rails 7.1.0, #worker.new.queue_name for ActionMailer::MailDeliveryJob returns is calculated dynamically based on the job's arguments.
        # it's now each mailer class that can define its own queue_name and even a custom delivery_job
        # if a custom delivery_job is defined, it is its responsibility to define its own queue_name in away that will work with advanced_sneakers_adapter
        next if ActionMailer.gem_version >= Gem::Version.new("7.1.0") && worker == ActionMailer::MailDeliveryJob

        AdvancedSneakersActiveJob.define_consumer(queue_name: worker.new.queue_name)
      end
    end

    def define_action_mailer_consumers
      mailer_classes = action_mailer_classes_with_matching_adapter
      mailer_classes.each do |mailer|
        # Before the changes in rails 7.1.0, when the ActionMailer#deliver_later_queue_name was nil
        # The queue_name was set to set to default ActiveJob queue_name ("default")
        # https://github.com/rails/rails/blob/961fc42f90e880516e8ec28cacc88e2425c78110/activejob/lib/active_job/queue_name.rb#L63
        # Since Rails 6.1, ActionMailer#deliver_later_queue_name is configured to nil
        # so we need to manually set a default value if the developers don't configured to a desired value
        queue_name = mailer.deliver_later_queue_name || "mailers" # "default"
        AdvancedSneakersActiveJob.define_consumer(queue_name:)
      end
    end

    private

    def active_job_classes_with_matching_adapter
      ([ActiveJob::Base] + ActiveJob::Base.descendants).select do |klass|
        klass.queue_adapter == ::ActiveJob::QueueAdapters::AdvancedSneakersAdapter ||
          klass.queue_adapter.is_a?(::ActiveJob::QueueAdapters::AdvancedSneakersAdapter)
      end
    end

    def action_mailer_classes_with_matching_adapter
      active_job_classes = active_job_classes_with_matching_adapter
      mailer_classes = ActionMailer::Base.descendants
      mailer_classes.select do |klass|
        active_job_classes.include?(klass.delivery_job)
      end
    end
  end
end
