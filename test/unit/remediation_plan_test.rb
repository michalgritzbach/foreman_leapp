# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanLeapp
  class RemediationPlanTest < ActiveSupport::TestCase
    # Taken from a leapp <= 0.21 report - leapp quoted the arguments itself.
    OLD_SYMLINK_CONTEXT = [
      'sh',
      '-c',
      '"ln -snf usr/lib /lib && ln -snf var/log/leapp /space space && ' \
      'ln -snf var/log/leapp /quote\'quote"',
    ].freeze

    # The very same remediation as reported by leapp >= 0.22 - the arguments
    # are reported verbatim. https://github.com/oamg/leapp-repository/pull/1520
    NEW_SYMLINK_CONTEXT = [
      'bash',
      '-c',
      'ln -snf "usr/lib" "/lib" && ln -snf "var/log/leapp" "/space space" && ' \
      'ln -snf "var/log/leapp" "/quote\'quote"',
    ].freeze

    describe '#command_line' do
      test 'joins the arguments verbatim when leapp did the quoting' do
        assert_equal OLD_SYMLINK_CONTEXT.join(' '),
          RemediationPlan.command_line(OLD_SYMLINK_CONTEXT, true)
      end

      test 'escapes the arguments when leapp reports them verbatim' do
        line = RemediationPlan.command_line(NEW_SYMLINK_CONTEXT, false)

        assert_equal NEW_SYMLINK_CONTEXT, Shellwords.split(line)
      end

      test 'escapes shell metacharacters when leapp reports them verbatim' do
        context = ['sed', '-i', 's/^AllowZoneDrifting=.*/AllowZoneDrifting=no/',
                   '/etc/firewalld/firewalld.conf']

        line = RemediationPlan.command_line(context, false)

        assert_equal context, Shellwords.split(line)
        assert_not_includes line, '.*'
      end
    end

    describe '#quoted_by_leapp?' do
      test 'true for leapp older than 0.22' do
        assert RemediationPlan.quoted_by_leapp?('0.21.0')
      end

      test 'false for leapp 0.22 and newer' do
        assert_not RemediationPlan.quoted_by_leapp?('0.22.0')
        assert_not RemediationPlan.quoted_by_leapp?('0.22')
      end

      test 'keeps the old quoting when the leapp version is unknown' do
        [nil, ''].each do |leapp_version|
          assert RemediationPlan.quoted_by_leapp?(leapp_version)
        end
      end

      test 'keeps the old quoting when the leapp version cannot be parsed' do
        assert RemediationPlan.quoted_by_leapp?('not-a-version')
      end

      test 'handles a leapp version with a release suffix' do
        assert_not RemediationPlan.quoted_by_leapp?('0.22.0-1.el9')
      end
    end

    describe '#build' do
      let(:detail) do
        { 'remediations' => [
          { 'type' => 'hint', 'context' => 'Set AllowZoneDrifting=no' },
          { 'type' => 'command', 'context' => %w[vgimportdevices] },
          { 'type' => 'command', 'context' => NEW_SYMLINK_CONTEXT },
        ] }
      end

      test 'renders one line per command remediation and skips the hints' do
        lines = RemediationPlan.build(detail, '0.22.0').lines

        assert_equal 2, lines.size
        assert_equal ['vgimportdevices'], Shellwords.split(lines.first)
        assert_equal NEW_SYMLINK_CONTEXT, Shellwords.split(lines.second)
      end

      test 'returns an empty plan when there is nothing to run' do
        assert_equal '', RemediationPlan.build(nil, '0.22.0')
        assert_equal '',
          RemediationPlan.build({ 'remediations' => [{ 'type' => 'hint', 'context' => 'meh.' }] },
            '0.22.0')
      end
    end
  end
end
