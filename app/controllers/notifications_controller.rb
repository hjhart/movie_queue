class NotificationsController < ApplicationController
  def poll
    notifications = Notification.unread
    notifications.each { |n| n.update_attributes({:read => true}) unless n.sticky }
    render json: notifications
  end

  def read
    id = params[:id]
    notification = Notification.find(id)
    notification.read = true
    notification.save
    render text: "Okay!"
  end
end
