# frozen_string_literal: true

require 'test_plugin_helper'

class PreupgradeReportEntryTest < ActiveSupport::TestCase
  should belong_to(:preupgrade_report)
  should belong_to(:host)

  should validate_presence_of(:preupgrade_report)
  should validate_presence_of(:host)
  should validate_presence_of(:hostname)
  should validate_presence_of(:title)
  should validate_presence_of(:actor)
  should validate_presence_of(:audience)
  should validate_presence_of(:severity)
  should validate_presence_of(:leapp_run_id)

  describe 'remediation_details' do
    setup do
      @host = FactoryBot.create(:host)

      report = FactoryBot.create(:preupgrade_report)
      @entry1 = FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: @host,
        leapp_version: '0.22.0')
      @entry2 = FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: @host, detail: nil)
    end

    it do
      details = PreupgradeReportEntry.remediation_details([@entry1.id, @entry2.id], @host.id)
      assert_equal details.size, 1
      assert_equal details[0], [@entry1.detail, '0.22.0']

      details = PreupgradeReportEntry.remediation_details([@entry1.id, @entry2.id], FactoryBot.create(:host))
      assert_equal details.size, 0
    end
  end

  describe 'scoped_search' do
    it 'filters correctly by has_remediation and inhibitor' do
      host = FactoryBot.create(:host)
      report = FactoryBot.create(:preupgrade_report)

      entry1 = FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: host,
        flags: ['inhibitor'],
        detail: { 'remediations' => [{ 'type' => 'hint' }] })
      entry2 = FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: host,
        flags: [],
        detail: nil)

      assert_includes PreupgradeReportEntry.search_for('inhibitor = yes'), entry1
      assert_not_includes PreupgradeReportEntry.search_for('inhibitor = yes'), entry2
      assert_includes PreupgradeReportEntry.search_for('has_remediation = no'), entry2
      assert_not_includes PreupgradeReportEntry.search_for('has_remediation = no'), entry1
    end

    it 'filters correctly by risk_factor (renamed from severity)' do
      host = FactoryBot.create(:host)
      report = FactoryBot.create(:preupgrade_report)

      high_entry = FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report,
        host: host, severity: 'high')
      info_entry = FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report,
        host: host, severity: 'info')

      assert_includes PreupgradeReportEntry.search_for('risk_factor = high'), high_entry
      assert_not_includes PreupgradeReportEntry.search_for('risk_factor = high'), info_entry
    end

    it 'orders semantically via order_by_severity scope' do
      host = FactoryBot.create(:host)
      report = FactoryBot.create(:preupgrade_report)
      FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: host, severity: 'high')
      FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: host, severity: 'info')
      FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: host, severity: 'medium')
      FactoryBot.create(:preupgrade_report_entry, preupgrade_report: report, host: host, severity: 'low')

      asc = PreupgradeReportEntry.order_by_severity('ASC').map(&:severity)
      assert_equal %w[info low medium high], asc

      desc = PreupgradeReportEntry.order_by_severity('DESC').map(&:severity)
      assert_equal %w[high medium low info], desc
    end
  end
end
