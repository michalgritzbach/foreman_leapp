# frozen_string_literal: true

class PreupgradeReport < ::Report
  belongs_to :job_invocation
  has_many :preupgrade_report_entries, dependent: :destroy

  scoped_search on: :job_invocation_id, only_explicit: true

  def self.create_report(host, data, job_invocation_id, leapp_version = nil)
    # We don't have specific permissions for the Preupgrade leapp reports,
    # so we need to skip the permission check for non-admin users.
    # The user is still required to have permission to run the job and view the hosts.
    skip_permission_check do
      report = PreupgradeReport.create  host: host, status: 0,
                                        job_invocation_id: job_invocation_id,
                                        reported_at: DateTime.now.utc

      data['entries']&.each do |entry|
        PreupgradeReportEntry.create! entry_params(report, entry, host, data, leapp_version)
      end
    end
  end

  def self.entry_params(report, entry, host, data, leapp_version = nil)
    { preupgrade_report: report,
      host_id: host.id,
      hostname: host.name,
      title: entry['title'],
      actor: entry['actor'],
      audience: entry['audience'],
      severity: entry['severity'],
      leapp_run_id: data['leapp_run_id'],
      leapp_version: leapp_version,
      summary: entry['summary'],
      tags: entry['tags'],
      flags: entry['flags'],
      detail: entry['detail'] }
  end
end
