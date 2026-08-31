# frozen_string_literal: true

module Actions
  module ForemanLeapp
    class PreupgradeJob < Actions::EntryAction
      # The `rpm -q leapp` line of the job output, e.g. leapp-0.21.0-1.el8.noarch
      LEAPP_NVR = /^leapp-(\d[\d.]*)/.freeze

      def self.subscribe
        Actions::RemoteExecution::RunHostJob
      end

      def plan(job_invocation, host, *_args)
        return unless ::Helpers::JobHelper.correct_feature?(job_invocation, 'leapp_preupgrade') ||
                      ::Helpers::JobHelper.correct_feature?(job_invocation, 'leapp_remediation_plan')

        plan_self(host_id: host.id, job_invocation_id: job_invocation.id)
      end

      def finalize(*_args)
        host = Host.find(input[:host_id])
        job_output = task.main_action.continuous_output.humanize
        leapp_report = format_output(job_output)

        PreupgradeReport.create_report(host, leapp_report, input[:job_invocation_id],
          format_version(job_output))
      end

      private

      def format_output(job_output)
        output = job_output.each_line(chomp: true)
                           .drop_while { |l| !l.start_with? '===leap_upgrade_report_start===' }.drop(1)
                           .take_while { |l| !l.start_with? 'Exit status:' }
                           .reject(&:empty?)
                           .join('')
        JSON.parse(output)
      end

      # The version of the leapp package the report was generated with. It drives
      # how the remediation commands from the report have to be quoted.
      def format_version(job_output)
        job_output[LEAPP_NVR, 1]
      end
    end
  end
end
