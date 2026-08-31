# frozen_string_literal: true

class AddLeappVersionToReportEntries < ActiveRecord::Migration[7.0]
  def change
    add_column :preupgrade_report_entries, :leapp_version, :string
  end
end
