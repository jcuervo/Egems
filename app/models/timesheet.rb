class Timesheet < ActiveRecord::Base
  # -------------------------------------------------------
  # Errors
  # -------------------------------------------------------
  class NoTimeoutError < StandardError; end
  class NoTimeinError < StandardError; end

  self.table_name = 'employee_timesheets'
  attr_accessible :date, :time_in, :time_out

  # -------------------------------------------------------
  # Modules
  # -------------------------------------------------------
  include ApplicationHelper

  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :time_in
  validates_presence_of :time_out, :on => :update
  validate :invalid_entries

  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :user, :foreign_key => :employee_id

  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :latest, lambda { |time = Time.now.beginning_of_day|
    where("Date(date) = Date(?)", time.utc)
  }
  scope :previous, :conditions => ["Date(date) < Date(?)", Time.now.beginning_of_day.utc]
  scope :no_timeout,  :conditions => ["time_in is not null and time_out is null"]
  scope :desc, :order => 'date desc, created_on desc'
  scope :within, lambda { |range|
    where(["Date(date) between Date(?) and Date(?)", range.first.utc, range.last.utc])
  }

  # -------------------------------------------------------
  # Class Methods
  # -------------------------------------------------------
  class << self
    def time_in!(user, force=false)
      latest_invalid_timesheets = user.timesheets.latest.no_timeout
      raise NoTimeoutError if latest_invalid_timesheets.present?
      raise NoTimeoutError if user.timesheets.previous.no_timeout.present? and !force
      timesheet = user.timesheets.new(:date => Time.now.beginning_of_day.utc,
                                      :time_in => Time.now.utc)
      timesheet.save!
    end

    def time_out!(user)
      latest = user.timesheets.latest.no_timeout
      raise NoTimeinError if latest.empty?
      timesheet = latest.desc.first
      timesheet.time_out = Time.now.utc
      timesheet.save!
    end
  end

  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def manual_update(attrs={})
    #TODO: invalid date & time format
    begin
      t_date = attrs[:date] ? Time.parse(attrs[:date]) : date.localtime
      t_hour = Time.parse(attrs[:hour] + attrs[:meridian]).strftime("%H")
      t_min = attrs[:min]
      time = Time.local(t_date.year, t_date.month, t_date.day, t_hour, t_min)
    rescue
      time = nil
    end
    type = time_out ? "time_in" : "time_out"
    self.attributes = { "date" => t_date.beginning_of_day, "#{type}" => time }
    begin
      if self.save!
        user = User.find_by_employee_id(employee_id)
        # Time in after manual timeout only if your manual timeout entry is for
        # the current day.
        if type.eql?("time_out") && time.today?
          self.class.time_in!(user) rescue NoTimeoutError
        end
        # TODO: move to instance method and rescue exceptions
        TimesheetMailer.invalid_timesheet(user, self, type).deliver
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end
  end

  def invalid_entries
    if time_in && time_out
      t_i, t_o = format_short_time_with_sec(time_in), format_short_time_with_sec(time_out)
      if time_in > time_out
        errors[:base] << "Time in (#{t_i}) shouldn't be later than Time out (#{t_o})."
      end
      
      if time_out > Time.now.utc
        errors[:base] << "Time out (#{t_o}) shouldn't be later than current time."
      end
      
      user = User.find_by_employee_id(employee_id)
      last_entry = user.timesheets.order(:created_on).last
      if last_entry && last_entry.time_out && time_in < last_entry.time_out
        errors[:base] << "Time in should be later than last entries."
      end
    end
  end
end
