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

  desc "Import users from old Pixeltech PostgreSQL. Usage: rake users:import_pixeltech OLD_DATABASE_URL=postgres://..."
  task import_pixeltech: :environment do
    require "pg"

    old_database_url = ENV["OLD_DATABASE_URL"]
    raise "Specify OLD_DATABASE_URL=postgres://user:pass@host:5432/dbname" if old_database_url.blank?

    sql = <<~SQL
      SELECT
        users.id,
        users.email,
        users.encrypted_password,
        users.username,
        users.created_at,
        users.updated_at,
        clients.ballance AS client_balance,
        clients.incoming AS client_incoming,
        clients.spent AS client_spent,
        STRING_AGG(DISTINCT roles.name, ',') AS role_names
      FROM users
      LEFT JOIN clients ON clients.user_id = users.id
      LEFT JOIN users_roles ON users_roles.user_id = users.id
      LEFT JOIN roles ON roles.id = users_roles.role_id
      GROUP BY
        users.id,
        users.email,
        users.encrypted_password,
        users.username,
        users.created_at,
        users.updated_at,
        clients.ballance,
        clients.incoming,
        clients.spent
      ORDER BY users.id ASC
    SQL

    imported = 0
    updated = 0
    skipped = 0

    conn = PG.connect(old_database_url)
    conn.exec(sql).each do |row|
      email = row["email"].to_s.strip.downcase
      if email.blank?
        skipped += 1
        next
      end

      old_roles = row["role_names"].to_s.split(",").map(&:strip).reject(&:blank?)
      mapped_role =
        if (old_roles & %w[superadmin admin]).any?
          :admin
        elsif old_roles.include?("client")
          :client
        else
          :user
        end

      source_balance_cents = ((row["client_balance"].presence || "0").to_d * 100).round.to_i
      imported_password_digest = row["encrypted_password"].to_s

      user = User.find_or_initialize_by(email:)
      new_record = user.new_record?

      user.role = mapped_role
      user.active = true
      user.external_id = "pixeltech:#{row['id']}"
      user.hourly_rate_cents ||= 0
      user.import_metadata = user.import_metadata.merge(
        "source" => "pixeltech",
        "source_user_id" => row["id"],
        "source_username" => row["username"],
        "source_roles" => old_roles,
        "source_client_balance" => row["client_balance"],
        "source_client_incoming" => row["client_incoming"],
        "source_client_spent" => row["client_spent"],
        "source_created_at" => row["created_at"],
        "source_updated_at" => row["updated_at"]
      )

      if imported_password_digest.present?
        user.password_digest = imported_password_digest
      elsif new_record
        generated_password = SecureRandom.base58(16)
        user.password = generated_password
        user.password_confirmation = generated_password
        user.import_metadata["generated_password"] = true
      end

      user.save!(validate: false)

      delta = source_balance_cents - user.balance_cents
      if delta != 0
        user.update_columns(balance_cents: source_balance_cents)
        user.balance_ledger_entries.create!(
          kind: :import_adjustment,
          amount_cents: delta,
          balance_after_cents: source_balance_cents,
          metadata: {
            source: "pixeltech",
            source_user_id: row["id"],
            imported_email: email
          }
        )
      end

      user.update_columns(
        created_at: Time.zone.parse(row["created_at"].to_s),
        updated_at: Time.zone.parse(row["updated_at"].to_s)
      )

      new_record ? imported += 1 : updated += 1
    end

    puts "Pixeltech import completed: imported=#{imported}, updated=#{updated}, skipped=#{skipped}"
  ensure
    conn&.close
  end
end
