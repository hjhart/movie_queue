class NotificationsController < ApplicationController
  def poll
    render json: Notification.unread
  end

  def read
    id = params[:id]
    notification = Notification.find(id)
    notification.read = true
    notification.save
    render text: "Okay!"
  end
end
