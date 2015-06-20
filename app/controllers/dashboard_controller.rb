class DashboardController < ApplicationController
  before_action :require_link_secret
  layout 'dashboard'
  
  def dash
  end

  def open_sesame
    alert_mesg = notice_mesg = nil
    if @user.has_active_session?
      if door_open_attempt
        notice_mesg = I18n.t(:door_is_open)
      else
        alert_mesg = 'Sorry, the door did not open. Please try again.'
      end
    else
      alert_mesg = 'No active session. Maybe you want to check in first?'
    end

    redirect_to "/dash/#{@user.plain_secret}", alert: alert_mesg, notice: notice_mesg
  end

  def checkin
    # Cannot check in if they can't pay
    alert_mesg = notice_mesg = nil
    
    if PaymentTokenRecord.find_by_user_id(@user.id)
      PaidSession.create!(user: @user, active: true, started_at: Time.now.utc)
      notice_mesg = 'Your session has started!'

      if door_open_attempt
        notice_mesg += ' ' + I18n.t(:door_is_open)
      else
        notice_mesg += ' Sorry, the door did not open. Please try again.'
      end      
    else
      alert_mesg = "error: We couldn't find payment information. Let us know if we got something wrong!"
    end

    redirect_to "/dash/#{@user.plain_secret}", alert: alert_mesg, notice: notice_mesg
  end
  
  def checkout
    if @user.inactivate_sessions!
      notice_mesg = t(:checked_out)
      PrepareInvoicesJob.perform_later(@user)
    else
      alert_mesg = 'failure'
    end

    redirect_to "/dash/#{@user.plain_secret}", alert: alert_mesg, notice: notice_mesg
  end

  private
  def door_open_attempt
    d = DoorMonitorRecord.new
    d.requestor = @user
    ret = false
    
    if DoorGenie.open_door
      d.door_response = true
      DoorEntryMailer.admin_notification_email(@user).deliver_later
      ret = true
    else
      d.door_response = false
    end
    d.save

    ret
  end
end
