# frozen_string_literal: true

require 'shellwords'

module ForemanLeapp
  # Assembles the shell script out of the command remediations found in a leapp report.
  #
  # Leapp changed the way remediation commands are quoted. Up to leapp 0.21 the
  # arguments in the "context" list were already quoted by leapp itself, so they
  # were meant to be joined verbatim. Starting with leapp 0.22 the arguments are
  # reported as they are and have to be escaped by the consumer of the report.
  # See https://github.com/oamg/leapp-repository/pull/1520
  #
  # The new quoting is shipped by leapp-upgrade-el<X>toel<Y> 0.25, which is released
  # together with leapp 0.22, so the version of the leapp package tells the two
  # formats apart.
  module RemediationPlan
    # The first leapp version that reports remediation command arguments unquoted.
    UNQUOTED_ARGUMENTS_SINCE = Gem::Version.new('0.22')

    class << self
      def build(detail, leapp_version)
        Array.wrap(detail)
             .map { |d| d['remediations'] }
             .flatten
             .compact
             .select { |remediation| remediation['type'] == 'command' }
             .map { |remediation| "#{command_line(remediation['context'], leapp_version)}\n" }
             .join
      end

      def command_line(context, leapp_version)
        arguments = Array.wrap(context).map(&:to_s)
        return arguments.join(' ') if quoted_by_leapp?(leapp_version)

        arguments.map { |argument| Shellwords.escape(argument) }.join(' ')
      end

      # Unknown versions are treated as old leapp, so that reports collected
      # before the version was recorded keep rendering the way they used to.
      def quoted_by_leapp?(leapp_version)
        version = Gem::Version.new(leapp_version.to_s[/\A[0-9][0-9.]*/].to_s.chomp('.'))
        version < UNQUOTED_ARGUMENTS_SINCE
      rescue ArgumentError
        true
      end
    end
  end
end
