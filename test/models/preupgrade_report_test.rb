# frozen_string_literal: true

require 'test_plugin_helper'

class PreupgradeReportTest < ActiveSupport::TestCase
  should belong_to(:job_invocation)
  should have_many(:preupgrade_report_entries).dependent(:destroy)

  describe '#create_report' do
    let(:job_invocation) { FactoryBot.create(:job_invocation) }
    let(:host) { FactoryBot.create(:host) }

    it 'with commands and hints' do
      data = { 'leapp_run_id' => 'leapp_c13e471c',
               'entries' => [sample_entry_1, sample_entry_2] }

      assert_difference -> { PreupgradeReport.count } => 1, -> { PreupgradeReportEntry.count } => 2 do
        PreupgradeReport.create_report(host, data, job_invocation)
      end
    end

    it 'stores the leapp version the report was generated with' do
      data = { 'leapp_run_id' => 'leapp_c13e471c', 'entries' => [sample_entry_1] }

      PreupgradeReport.create_report(host, data, job_invocation, '0.22.0')

      assert_equal ['0.22.0'], PreupgradeReportEntry.where(host: host).pluck(:leapp_version)
    end

    it 'leaves the leapp version empty when it is not known' do
      data = { 'leapp_run_id' => 'leapp_c13e471c', 'entries' => [sample_entry_1] }

      PreupgradeReport.create_report(host, data, job_invocation)

      assert_nil PreupgradeReportEntry.where(host: host).first.leapp_version
    end

    it 'no entries' do
      data = { 'leapp_run_id' => 'leapp_c13e471c' }

      assert_difference -> { PreupgradeReport.count } => 1, -> { PreupgradeReportEntry.count } => 0 do
        PreupgradeReport.create_report(host, data, job_invocation)
      end
    end
  end

  def sample_entry_1
    { 'severity' => 'low', 'title' => 'SElinux will be set to permissive mode',
      'tags' => %w[selinux security], 'actor' => 'check_se_linux',
      'summary' => 'sum', 'audience' => 'sysadmin', 'id' => 'id1' }
  end

  def sample_entry_2
    { 'severity' => 'high', 'tags' => ['kernel'], 'title' => 'Multiple devel kernels installed',
      'detail' => { 'remediations' => [
        { 'type' => 'hint', 'context' => 'Some context' },
        { 'type' => 'command', 'context' => ['yum', '-y', 'remove', 'kernel-devel-3.10.0.1127.el7'] }
      ] },
      'actor' => 'check_installed_devel_kernels', 'summary' => 'Sum', 'audience' => 'sysadmin',
      'flags' => ['inhibitor'], 'id' => 'id2' }
  end
end
