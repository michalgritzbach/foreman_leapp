# frozen_string_literal: true

class PreupgradeReportEntry < ApplicationRecord
  belongs_to :preupgrade_report
  belongs_to_host

  serialize :tags, Array
  serialize :flags, Array
  serialize :detail, JSON

  validates :preupgrade_report, :host, :hostname, :title, :actor,
    :audience, :severity, :leapp_run_id, presence: true

  scoped_search on: :title, complete_value: true
  scoped_search on: :hostname, complete_value: true
  scoped_search on: :summary

  scoped_search on: :severity,
    rename: :risk_factor,
    complete_value: { high: 'high', medium: 'medium', low: 'low', info: 'info' }

  scoped_search on: :flags,
    rename: :inhibitor,
    only_explicit: true,
    operators: ['=', '!='],
    complete_value: { yes: 'yes', no: 'no' },
    ext_method: :search_yes_no_fields

  scoped_search on: :detail,
    rename: :has_remediation,
    only_explicit: true,
    operators: ['=', '!='],
    complete_value: { yes: 'yes', no: 'no' },
    ext_method: :search_yes_no_fields

  scoped_search on: :detail,
    rename: :fix_type,
    only_explicit: true,
    operators: ['=', '!='],
    complete_value: { hint: 'hint', command: 'command' },
    ext_method: :search_fix_type

  # info(1) < low(2) < medium(3) < high(4)
  scope :order_by_severity, lambda { |direction = 'ASC'|
    dir = direction.to_s.casecmp('DESC').zero? ? 'DESC' : 'ASC'
    order(Arel.sql(
      "CASE preupgrade_report_entries.severity " \
      "WHEN 'high' THEN 4 WHEN 'medium' THEN 3 " \
      "WHEN 'low' THEN 2 WHEN 'info' THEN 1 ELSE 0 END #{dir}"
    ))
  }

  # Returns [detail, leapp_version] pairs. The leapp version is needed because
  # the quoting of the remediation commands differs between leapp versions.
  def self.remediation_details(remediation_ids, host)
    where(id: remediation_ids, host: host).where.not(detail: nil).pluck(:detail, :leapp_version)
  end

  def self.search_yes_no_fields(key, operator, value)
    column, term = case key.to_sym
                   when :inhibitor       then %w[flags inhibitor]
                   when :has_remediation then %w[detail remediations]
                   else raise Foreman::Exception,
                     N_("Unknown search key '%s' for search_yes_no_fields") % key
                   end

    if (operator == '=' && value == 'yes') || (operator == '!=' && value == 'no')
      { conditions: "preupgrade_report_entries.#{column} LIKE '%%#{term}%%'" }
    else
      { conditions: "(preupgrade_report_entries.#{column} NOT LIKE '%%#{term}%%' OR " \
                    "preupgrade_report_entries.#{column} IS NULL)" }
    end
  end

  def self.search_fix_type(_key, operator, value)
    unless %w[hint command].include?(value.to_s.downcase)
      raise Foreman::Exception, N_("Unknown fix_type value '%s' for search_fix_type") % value
    end

    safe_value = sanitize_sql_like(value.to_s.downcase)
    like_op    = (operator == '=') ? 'LIKE' : 'NOT LIKE'

    conditions = "(preupgrade_report_entries.detail #{like_op} " \
                 "'%%\"type\":\"#{safe_value}\"%%' OR " \
                 "preupgrade_report_entries.detail #{like_op} " \
                 "'%%\"type\": \"#{safe_value}\"%%')"
    conditions = "(#{conditions} OR preupgrade_report_entries.detail IS NULL)" if operator == '!='
    { conditions: conditions }
  end
end
