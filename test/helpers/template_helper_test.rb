# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanLeapp
  class TemplateHelperTest < ActionView::TestCase
    let(:host) { FactoryBot.create(:host) }
    let(:report) { FactoryBot.create(:preupgrade_report, host: host) }
    let(:entry) { FactoryBot.create(:preupgrade_report_entry, host: host, preupgrade_report: report) }

    let(:quoting_context) do
      {
        remediations: [
          {
            type: 'command',
            context: ['bash', '-c', 'ln -snf "var/log/leapp" "/space space"'],
          },
        ],
      }
    end

    describe 'build_remediation_plan' do
      test 'with remediation commands' do
        template = build_remediation_plan([entry.id], host)
        assert_equal template, "yum -y remove leapp_pkg\n"
      end

      test 'without remediation commands' do
        empty_entry = FactoryBot.create(:preupgrade_report_entry, host: host, preupgrade_report: report,
          detail: { remediations: [{ type: 'hint',
                                     context: 'meh.' }] })
        template = build_remediation_plan([empty_entry.id], host)
        assert_equal template, ''
      end

      test 'only for current host' do
        template = build_remediation_plan([entry.id], FactoryBot.create(:host))
        assert_equal template, ''
      end

      test 'joins the arguments verbatim for reports from leapp older than 0.22' do
        old_entry = FactoryBot.create(:preupgrade_report_entry, host: host, preupgrade_report: report,
          leapp_version: '0.21.0', detail: quoting_context)

        template = build_remediation_plan([old_entry.id], host)

        assert_equal "bash -c ln -snf \"var/log/leapp\" \"/space space\"\n", template
      end

      test 'escapes the arguments for reports from leapp 0.22 and newer' do
        new_entry = FactoryBot.create(:preupgrade_report_entry, host: host, preupgrade_report: report,
          leapp_version: '0.22.0', detail: quoting_context)

        template = build_remediation_plan([new_entry.id], host)

        assert_equal ['bash', '-c', 'ln -snf "var/log/leapp" "/space space"'],
          Shellwords.split(template)
      end

      test 'quotes every entry according to the leapp version it was reported by' do
        old_entry = FactoryBot.create(:preupgrade_report_entry, host: host, preupgrade_report: report,
          leapp_version: '0.21.0', detail: quoting_context)
        new_entry = FactoryBot.create(:preupgrade_report_entry, host: host, preupgrade_report: report,
          leapp_version: '0.22.0', detail: quoting_context)

        lines = build_remediation_plan([old_entry.id, new_entry.id], host).lines
        verbatim_line = "bash -c ln -snf \"var/log/leapp\" \"/space space\"\n"

        assert_equal 2, lines.size
        assert_includes lines, verbatim_line
        assert_equal ['bash', '-c', 'ln -snf "var/log/leapp" "/space space"'],
          Shellwords.split(lines.find { |line| line != verbatim_line })
      end
    end
  end
end
