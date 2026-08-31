# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanLeapp
  class PreupgradeJobTest < ActiveSupport::TestCase
    include Dynflow::Testing

    let(:host) { FactoryBot.create(:host) }
    let(:job_template) do
      FactoryBot.create(:job_template, template: 'echo "1"', job_category: 'leapp',
        provider_type: 'SSH', name: 'Leapp preupgrade')
    end
    let(:job_invocation) { FactoryBot.create(:job_invocation) }
    let(:template_invocation) do
      FactoryBot.create(:template_invocation, template: job_template, job_invocation: job_invocation)
    end

    let(:action) { create_action(Actions::ForemanLeapp::PreupgradeJob) }
    let(:planned_action) { plan_action(action, job_invocation, host, template_invocation) }

    setup do
      RemoteExecutionFeature.find_by(label: 'leapp_preupgrade').update(job_template: job_template)
    end

    describe 'plan' do
      test 'run plan phase' do
        assert_equal planned_action.input['host_id'], host.id
        assert_equal planned_action.input['job_invocation_id'], job_invocation.id
      end
    end

    describe '#format_output' do
      let(:output) { "first_line\n===leap_upgrade_report_start===\n{\n\"report\": \"yes!\"\n}\nExit status: 0\n" }

      it { assert action.send(:format_output, output), '{"report": "yes!"}' }
    end

    describe 'finalize' do
      it { assert_finalize_phase planned_action }
    end
  end

  # Parsing the job output does not need any of the remote execution setup.
  class PreupgradeJobOutputTest < ActiveSupport::TestCase
    include Dynflow::Testing

    let(:action) { create_action(Actions::ForemanLeapp::PreupgradeJob) }

    describe '#format_version' do
      test 'picks the leapp version up from the rpm output' do
        output = "leapp-0.22.0-1.el9.noarch\n===leap_upgrade_report_start===\n{}\nExit status: 0\n"

        assert_equal '0.22.0', action.send(:format_version, output)
      end

      test 'ignores other leapp packages' do
        output = "leapp-upgrade-el8toel9-0.25.0-1.el8.noarch\nleapp-0.22.0-1.el8.noarch\n"

        assert_equal '0.22.0', action.send(:format_version, output)
      end

      test 'returns nil when the leapp package is not reported' do
        output = "package leapp is not installed\n===leap_upgrade_report_start===\n{}\n"

        assert_nil action.send(:format_version, output)
      end
    end
  end
end
