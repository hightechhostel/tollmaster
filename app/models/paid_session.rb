class PaidSession < ActiveRecord::Base
  belongs_to :user
  belongs_to :invoice
  
  def duration(unit: :seconds)
    # inactive = sessions whose active attribute if false, OR ones that started yesterday or earlier will yield a duration
    if !is_inactive?
      nil
    else
      if active
        # The session ended without 
        duration = PaidSession.end_of_day - (started_at.hour * 3600 + started_at.min * 60 + started_at.sec)
      else
        duration = ended_at - started_at
      end

      if unit == :seconds
        duration
      else
        # For now we'll return milliseconds if the unit is unknown
        duration * 1000
      end
    end
  end

  def is_inactive?
    a = Date.today
    !active || (started_at.year < a.year ||
                   started_at.month < a.month ||
                   started_at.day < a.day)

  end
  
  def self.end_of_day
    # Official end of day has to be set
    Rails.application.secrets.end_of_day_24h.hour * 60 * 60
  end

  def session_cost
    duration(unit: :seconds).to_i * Rails.application.secrets.session_price_per_second
  end
end
