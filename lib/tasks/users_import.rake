namespace :users do
  desc "Import users from CSV. Usage: rake users:import CSV=path/to/file.csv"
  task import: :environment do
    require "csv"

    csv_path = ENV["CSV"]
    raise "Specify CSV=path/to/file.csv" if csv_path.blank?

    CSV.foreach(csv_path, headers: true) do |row|
      email = row.fetch("email").to_s.strip.downcase
      raise "email is required" if email.blank?

      user = User.find_or_initialize_by(email:)
      was_new = user.new_record?
      user.password = row["password"].presence || SecureRandom.base58(16) if was_new || row["password"].present?
      user.role = row["role"].presence || user.role || :client
      user.hourly_rate_cents = row["hourly_rate_cents"].presence&.to_i || user.hourly_rate_cents || 0
      user.active = row["active"].blank? ? true : ActiveModel::Type::Boolean.new.cast(row["active"])
      user.external_id = row["external_id"].presence || user.external_id
      user.import_metadata = user.import_metadata.merge("source" => row["source"].presence || "csv")
      user.save!

      next if row["balance_cents"].blank?

      delta = row["balance_cents"].to_i - user.balance_cents
      next if delta.zero?

      Users::BalanceManager.apply_delta!(
        user:,
        amount_cents: delta,
        kind: :import_adjustment,
        metadata: { source: "csv", imported_email: email }
      )
    end

    puts "Import completed"
  end
end
