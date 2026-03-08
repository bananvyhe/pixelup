class HourlyBalanceSweepJob
  include Sidekiq::Job

  def perform
    billing_hour = Time.current.beginning_of_hour

    User.billable.find_each do |user|
      debit_user!(user, billing_hour)
    end
  end

  private

  def debit_user!(user, billing_hour)
    user.with_lock do
      return if user.last_hourly_charge_at.present? && user.last_hourly_charge_at >= billing_hour
      return if user.effective_hourly_rate_cents <= 0

      Users::BalanceManager.apply_delta!(
        user:,
        amount_cents: -user.effective_hourly_rate_cents,
        kind: :hourly_charge,
        metadata: { billed_hour: billing_hour.iso8601 },
        lock: false
      )
      user.update!(last_hourly_charge_at: billing_hour)
    end
  end
end
