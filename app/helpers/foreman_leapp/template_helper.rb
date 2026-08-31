# frozen_string_literal: true

module ForemanLeapp
  module TemplateHelper
    def build_remediation_plan(remediation_ids, host)
      PreupgradeReportEntry.remediation_details(remediation_ids, host)
                           .map { |detail, leapp_version| RemediationPlan.build(detail, leapp_version) }
                           .join
    end
  end
end
