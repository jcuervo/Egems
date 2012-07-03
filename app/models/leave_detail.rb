class LeaveDetail < ActiveRecord::Base

  self.table_name = 'employee_truancy_details'
  attr_accessible :leave_type, :leave_date, :end_date, :leave_unit, :details, :period
  
  # -------------------------------------------------------
  # Modules
  # -------------------------------------------------------
  include ApplicationHelper
  
  # -------------------------------------------------------
  # Relationships / Associations
  # -------------------------------------------------------
  belongs_to :employee
  belongs_to :leave, :class_name => 'Leave', :foreign_key => :employee_truancy_id
  belongs_to :responder, :class_name => "Employee", :foreign_key => :responder_id
  has_and_belongs_to_many :responders, :class_name => "Employee",
                          :join_table => "employee_truancy_detail_responders",
                          :foreign_key => :employee_truancy_detail_id,
                          :association_foreign_key => :responder_id
  
  # -------------------------------------------------------
  # Validations
  # -------------------------------------------------------
  validates_presence_of :leave_type, :leave_unit, :details
  validates_numericality_of :leave_unit
  validates_inclusion_of :period, :in => 0 .. 2, :message => "period is invalid."
  validate :invalid_leave
  
  # -------------------------------------------------------
  # Callbacks
  # -------------------------------------------------------
  before_save :set_period
  before_create :set_default_responders
  before_create :set_leave
  after_save :send_email_notification
  
  # -------------------------------------------------------
  # Namescopes
  # -------------------------------------------------------
  scope :active, includes(:leave).where("employee_truancies.status = 1")
  scope :type, lambda { |type| where(:leave_type => type).order(:leave_date) }
  scope :pending, where(:status => 'Pending')
  scope :asc, order(:leave_date, :period)
  scope :find_half_day, lambda { |date, period|
    where("leave_date = ? AND period = ?", date, period)
  }
  
  # -------------------------------------------------------
  #  Constants
  # -------------------------------------------------------
  LEAVE_PERIOD = ["Whole Day", "AM", "PM", "Range"]
  
  # -------------------------------------------------------
  #  Class Methods
  # -------------------------------------------------------
  class << self
    def get_units_per_leave_date
      units_per_leave_date = {}
      self.active.each do |ld|
        local_leave_date = ld.leave_date.localtime.to_date
        if ld.leave_unit > 1
          startDate = local_leave_date
          endDate = startDate + ld.leave_unit.days
          (startDate ... endDate).each do |day|
            units_per_leave_date[day.to_s] = 1.0
          end
        elsif ld.leave_unit < 1 && units_per_leave_date[local_leave_date.to_s]
          units_per_leave_date[local_leave_date.to_s] += ld.leave_unit
        elsif ld.leave_unit < 1 && !units_per_leave_date[local_leave_date.to_s]
          units_per_leave_date[local_leave_date.to_s] = ld.leave_unit
        else
          units_per_leave_date[local_leave_date.to_s] = ld.leave_unit
        end
      end
      return units_per_leave_date
    end
  end
  
  # -------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------
  def end_date=(date)
    @end_date = Time.parse(date.to_s).utc rescue nil
  end
  
  def end_date
    @end_date
  end
  
  # returns {<mm/dd/yyyy> to <mm/dd/yyyy> or <mm/dd/yyyy AM/PM> or <mm/dd/yyyy>}
  def dated_on
    start_date = leave_date.localtime.to_date
    end_date = (start_date + leave_unit.ceil.days)
    range = (start_date ... end_date).to_a
    l_start_date = I18n.l(range.first, :format => :long_date_with_day)
    l_end_date = I18n.l(range.last, :format => :long_date_with_day) unless range.count == 1
    date = [l_start_date, l_end_date].compact.join(' to ')
    am_pm = {1 => "AM", 2 => "PM"}[period]
    [date, am_pm].compact.join(" ")
  end
  
  def set_leave
    self.leave = self.employee.leaves.type(self.leave_type).first
  end
  
  def set_period
    leave_date_local = leave_date.localtime.to_date
    end_date_local = end_date.localtime.to_date
    if (leave_date_local .. end_date_local).count > 1
      self.period = 3
    end
  end
  
  def set_default_responders
    managers = [employee.project_manager, employee.immediate_supervisor].compact.uniq
    responders << managers
  end
  
  def send_email_notification
    recipients = [employee]
    if employee.immediate_supervisor == employee.project_manager
      recipients << employee.project_manager
    else
      recipients.concat([employee.project_manager,employee.immediate_supervisor]).compact
    end

    recipients.compact.each do |recipient|
      begin
        LeaveDetailMailer.leave_approval(employee, self, recipient).deliver
      rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        errors[:base] << "There was a problem on sending the email notification to #{recipient.email}: #{e.message}"
        next
      end
    end
  end
  
  def invalid_leave
    @employee = self.employee
    @leave = self.leave || @employee.leaves.type(self.leave_type).first
    if validate_dates && validate_active
      allocated = @leave.leaves_allocated.to_f
      consumed = @leave.leaves_consumed.to_f
      pending_leaves = @leave.leave_details.active.pending
      pending_leave_units = pending_leaves.sum(:leave_unit).to_f
      remaining_leaves = allocated - consumed
      total_leaves = leave_unit.to_f + consumed + pending_leave_units
      if leave_type != "Absent Without Pay"
        validate_date_range(:leave_date, valid_range)
        validate_date_range(:end_date, valid_range)
        validate_leave_balance(total_leaves, remaining_leaves)
        validate_date_of_filing
      end
      validate_leave_conflicts
      validate_whole_day
      validate_half_day
      validate_leave_unit
    end
  end
  
private
  def validate_dates
    if valid_date?(:leave_date) && valid_date?(:end_date)
      @leave_date_local = leave_date.localtime.to_date
      @end_date_local = end_date.localtime.to_date
      if @leave_date_local > @end_date_local
        errors[:base] << "Leave date shouldn't be later than End date."
        return false
      else
        return true
      end
    end
  end
  
  def valid_date?(date_attr)
    begin
      Date.parse(self.send(date_attr).to_s)
      return true
    rescue
      errors[date_attr] << "is invalid."
      return false
    end
  end
  
  def valid_range
    date_from = @leave.date_from.localtime.to_date
    date_to = @leave.date_to.localtime.to_date
    
    case leave_type
    when "Vacation Leave"
      min_date, max_date = Date.today + 1.day, date_to
    when "Sick Leave", "Emergency Leave"
      min_date, max_date = date_from, Date.today
    else
      min_date, max_date = date_from, date_to
    end
    return Range.new(min_date, max_date)
  end
  
  def validate_active
    if !@leave.active?
      errors[:base] << "Leave credits has already been expired."
      return false
    else
      return true
    end
  end
  
  def validate_date_range(date_attr, range)
    if range && !range.include?(self.send(date_attr).to_date)
      errors[date_attr] << "is invalid. Should be within
                            #{range.first} and #{range.last}."
    end
  end
  
  def validate_leave_balance(total, remaining)
    if total > remaining
      errors[:base] << "You don't have enough leave credits."
    end
  end
  
  def validate_leave_conflicts
    units_per_leave_date = @employee.leave_details.get_units_per_leave_date
    startDate = @leave_date_local
    endDate = startDate + leave_unit.ceil.days
    maxed_out_leaves = []
    leave_dates = (startDate ... endDate).to_a
    units = ((leave_dates.count > 1)? 1 : leave_unit)
    leave_dates.each do |day|
      if (units_per_leave_date[day.to_s].to_f + units) > 1
        maxed_out_leaves << day
      end
    end
    
    conflict_leaves = maxed_out_leaves & leave_dates
    if !conflict_leaves.blank?
      dates = conflict_leaves.map { |d| format_date(d) }.compact.join(', ')
      errors[:base] << "You can no longer file leave(s) for
                        the ff. date(s): #{dates}"
    end
  end
  
  def validate_whole_day
    if [0, 3].include?(period) && leave_unit < 1
      errors[:leave_unit] << "should not be less than 1 if not a half day leave."
    end
  end
  
  def validate_half_day
    half_day = @employee.leave_details.find_half_day(leave_date, period).first
    if [1, 2].include?(period)
      if half_day
        errors[:base] << "You already have a #{period.ordinalize} period
                          half day leave on #{format_date leave_date}."
      end
      
      if @leave_date_local != @end_date_local
        errors[:base] << "Leave date should be equal to End date
                          if applying for a half day leave."
      end
      
      if leave_unit != 0.5
        errors[:leave_unit] << "should be equal to 0.5 if applying
                                for a half day leave."
      end
    end
  end
  
  def validate_date_of_filing
    if ["Sick Leave", "Emergency Leave"].include?(leave_type) && @end_date_local == Date.today
      if [0, 2].include?(period) || (period == 1 && Time.now < Time.parse("12pm"))
        errors[:base] << "Date of filing should always be after the
                          availment of leave."
      end
    end
  end
  
  def validate_leave_unit
    total_days = (@leave_date_local .. @end_date_local).count
    if !leave_unit == total_days
      errors[:leave_unit] << "is invalid."
    end
  end

end
