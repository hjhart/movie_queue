class Notification < ActiveRecord::Base
  def self.unread
    Notification.all(:conditions => { :read => false })
  end

  def as_json(options = {})
    super(:only => [:id, :notification])
  end
end
