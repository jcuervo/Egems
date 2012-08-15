# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120815025809) do

  create_table "branches", :force => true do |t|
    t.string "code",         :limit => 10,  :default => "", :null => false
    t.string "name",         :limit => 100, :default => "", :null => false
    t.text   "description"
    t.string "address"
    t.string "telephone_no"
    t.string "fax_number"
  end

  add_index "branches", ["code"], :name => "branches_code_idx"
  add_index "branches", ["name"], :name => "branches_name_idx"

  create_table "departments", :force => true do |t|
    t.string   "code",        :limit => 10,  :default => "",                    :null => false
    t.string   "name",        :limit => 100, :default => "",                    :null => false
    t.text     "description"
    t.integer  "head_id"
    t.datetime "created_on",                 :default => '1970-01-01 00:00:00'
    t.datetime "updated_on"
  end

  add_index "departments", ["code"], :name => "departments_code_idx"
  add_index "departments", ["name"], :name => "departments_name_idx"

  create_table "employee_shift_schedules", :force => true do |t|
    t.integer  "employee_id",       :default => 0,                     :null => false
    t.integer  "shift_schedule_id", :default => 0,                     :null => false
    t.datetime "start_date",        :default => '1970-01-01 00:00:00', :null => false
    t.datetime "end_date",          :default => '1970-01-01 00:00:00', :null => false
  end

  create_table "employee_timesheets", :force => true do |t|
    t.integer  "employee_id",                       :default => 0, :null => false
    t.datetime "date",                                             :null => false
    t.datetime "time_in"
    t.datetime "time_out"
    t.integer  "duration",                          :default => 0
    t.string   "remarks"
    t.integer  "is_late",                           :default => 0
    t.integer  "minutes_late",                      :default => 0
    t.integer  "is_undertime",                      :default => 0
    t.integer  "minutes_undertime",                 :default => 0
    t.datetime "created_on"
    t.integer  "created_by"
    t.datetime "updated_on"
    t.integer  "updated_by"
    t.integer  "is_valid",                          :default => 0
    t.integer  "is_day_awol",                       :default => 0
    t.integer  "is_am_awol",                        :default => 0
    t.integer  "is_pm_awol",                        :default => 0
    t.integer  "minutes_excess",                    :default => 0
    t.integer  "is_excess_minutes_applied",         :default => 0
    t.integer  "allowance_minutes_applied",         :default => 0
    t.integer  "overtime_minutes_applied",          :default => 0
    t.integer  "shift_schedule_id",                 :default => 0, :null => false
    t.integer  "shift_schedule_detail_id",          :default => 0, :null => false
    t.integer  "next_day_shift_schedule_id",        :default => 0, :null => false
    t.integer  "next_day_shift_schedule_detail_id", :default => 0, :null => false
  end

  add_index "employee_timesheets", ["employee_id", "date"], :name => "employee_timesheets_employee_id_index"
  add_index "employee_timesheets", ["is_late", "employee_id", "date"], :name => "employee_timesheets_is_late_index"
  add_index "employee_timesheets", ["is_undertime", "employee_id", "date"], :name => "employee_timesheets_is_undertime_index"
  add_index "employee_timesheets", ["is_valid", "employee_id", "date"], :name => "employee_timesheets_is_valid_index"

  create_table "employee_truancies", :force => true do |t|
    t.integer  "employee_id",      :default => 0,                     :null => false
    t.string   "leave_type",       :default => "Vacation Leave",      :null => false
    t.datetime "date_from",        :default => '1970-01-01 00:00:00', :null => false
    t.datetime "date_to",          :default => '1970-01-01 00:00:00', :null => false
    t.float    "leaves_allocated"
    t.float    "leaves_consumed"
    t.integer  "status",           :default => 1
    t.datetime "created_on",       :default => '1970-01-01 00:00:00'
    t.datetime "updated_on"
  end

  add_index "employee_truancies", ["employee_id", "leave_type", "status"], :name => "employee_truancies_1_idx"

  create_table "employee_truancy_detail_responders", :force => true do |t|
    t.integer "employee_truancy_detail_id"
    t.integer "responder_id"
  end

  add_index "employee_truancy_detail_responders", ["employee_truancy_detail_id"], :name => "ployee_truancy_detail_responders_employee_truancy_detail_id_idx"
  add_index "employee_truancy_detail_responders", ["responder_id"], :name => "employee_truancy_detail_responders_responder_id_idx"

  create_table "employee_truancy_details", :force => true do |t|
    t.integer  "employee_id",            :default => 0,                     :null => false
    t.integer  "employee_truancy_id",    :default => 0,                     :null => false
    t.datetime "leave_date",             :default => '1970-01-01 00:00:00', :null => false
    t.string   "details",                :default => "",                    :null => false
    t.string   "leave_type",             :default => "Sick Leave",          :null => false
    t.float    "leave_unit"
    t.integer  "period",                 :default => 0
    t.string   "status",                 :default => "Pending"
    t.datetime "created_on",             :default => '1970-01-01 00:00:00'
    t.datetime "updated_on"
    t.integer  "responder_id"
    t.string   "response"
    t.datetime "responded_on"
    t.integer  "actual_responder_id"
    t.datetime "optional_to_leave_date"
  end

  add_index "employee_truancy_details", ["employee_id", "employee_truancy_id"], :name => "employee_truancy_details_1_idx"

  create_table "employees", :force => true do |t|
    t.string   "employee_code",               :limit => 20, :default => "",                    :null => false
    t.string   "title",                       :limit => 10
    t.string   "first_name",                  :limit => 50, :default => "",                    :null => false
    t.string   "last_name",                   :limit => 50, :default => "",                    :null => false
    t.string   "middle_name",                 :limit => 50
    t.string   "full_name"
    t.string   "maiden_name"
    t.string   "other_name"
    t.string   "gender",                      :limit => 1,  :default => "M",                   :null => false
    t.datetime "birthdate",                                 :default => '1970-01-01 00:00:00'
    t.string   "birthplace"
    t.string   "email"
    t.integer  "shift_schedule_id",                         :default => 0,                     :null => false
    t.integer  "employee_supervisor_id",                    :default => 0,                     :null => false
    t.integer  "current_job_position_id",                   :default => 0,                     :null => false
    t.integer  "current_department_id",                     :default => 0,                     :null => false
    t.datetime "date_hired",                                :default => '1970-01-01 00:00:00', :null => false
    t.string   "employment_status",                         :default => "Active",              :null => false
    t.datetime "created_on",                                :default => '1970-01-01 00:00:00'
    t.integer  "created_by",                                :default => 0
    t.datetime "updated_on"
    t.integer  "updated_by"
    t.integer  "branch_id",                                 :default => 1,                     :null => false
    t.datetime "date_regularized",                          :default => '1970-01-01 00:00:00'
    t.integer  "employee_project_manager_id"
  end

  add_index "employees", ["birthdate", "full_name"], :name => "employees_1_idx"
  add_index "employees", ["employee_code"], :name => "employees_employee_code_idx"
  add_index "employees", ["full_name"], :name => "employees_full_name_idx"

  create_table "holiday_branches", :force => true do |t|
    t.integer "holiday_id"
    t.integer "branch_id"
  end

  create_table "holiday_exclusions", :force => true do |t|
    t.integer "holiday_id"
    t.integer "employee_id"
  end

  create_table "holidays", :force => true do |t|
    t.datetime "date",                       :default => '1970-01-01 00:00:00', :null => false
    t.string   "name",         :limit => 50, :default => "",                    :null => false
    t.text     "description",                                                   :null => false
    t.string   "holiday_type",               :default => "Regular Holiday",     :null => false
    t.float    "ot_rate"
  end

  add_index "holidays", ["date"], :name => "holidays_date_idx"
  add_index "holidays", ["name"], :name => "holidays_name_idx"

  create_table "shift_schedule_details", :force => true do |t|
    t.integer  "shift_schedule_id", :default => 0, :null => false
    t.integer  "day_of_week",       :default => 0, :null => false
    t.datetime "am_time_start"
    t.integer  "am_time_duration",  :default => 0
    t.integer  "am_time_allowance", :default => 0
    t.datetime "pm_time_start"
    t.integer  "pm_time_duration",  :default => 0
    t.integer  "pm_time_allowance", :default => 0
    t.float    "differential_rate"
  end

  add_index "shift_schedule_details", ["shift_schedule_id", "day_of_week"], :name => "shift_schedule_details_1_idx"

  create_table "shift_schedules", :force => true do |t|
    t.string   "name",              :default => "",                    :null => false
    t.string   "description",       :default => "",                    :null => false
    t.datetime "created_on",        :default => '1970-01-01 00:00:00'
    t.datetime "updated_on"
    t.integer  "is_strict",         :default => 1,                     :null => false
    t.integer  "is_custom",         :default => 0,                     :null => false
    t.float    "differential_rate"
  end

  add_index "shift_schedules", ["name"], :name => "shift_schedules_name_idx"

  create_table "truancy_actions", :force => true do |t|
    t.integer  "employee_truancy_id", :default => 0,                     :null => false
    t.integer  "responder_id",        :default => 0,                     :null => false
    t.string   "response",            :default => "Pending",             :null => false
    t.datetime "created_at",          :default => '1970-01-01 00:00:00'
    t.datetime "updated_at"
  end

  add_index "truancy_actions", ["employee_truancy_id"], :name => "truancy_actions_employee_truancy_id_idx"
  add_index "truancy_actions", ["responder_id", "employee_truancy_id"], :name => "truancy_actions_1_idx"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "encrypted_password",        :limit => 40
    t.string   "password_salt",             :limit => 40
    t.integer  "employee_id",                             :default => 0, :null => false
    t.integer  "enabled",                                 :default => 0
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "role_id",                                 :default => 0
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                           :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "authentication_token"
  end

  add_index "users", ["email"], :name => "altered_users_email_index"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["email"], :name => "users_email_idx"
  add_index "users", ["login"], :name => "altered_users_login_index"
  add_index "users", ["login"], :name => "users_login_idx"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
