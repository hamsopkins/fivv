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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170919005500) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "conference_contacts", force: :cascade do |t|
    t.integer  "conference_id", null: false
    t.integer  "contact_id",    null: false
    t.string   "pin",           null: false
    t.string   "call_sid"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["conference_id", "call_sid"], name: "index_conference_contacts_on_conference_id_and_call_sid", using: :btree
  end

  create_table "conferences", force: :cascade do |t|
    t.string   "name",                          null: false
    t.integer  "user_id",                       null: false
    t.datetime "start_time",                    null: false
    t.datetime "end_time",                      null: false
    t.boolean  "moderated",      default: true
    t.string   "access_code"
    t.string   "admin_pin",                     null: false
    t.string   "conf_sid"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "admin_call_sid"
    t.index ["admin_call_sid"], name: "index_conferences_on_admin_call_sid", using: :btree
    t.index ["conf_sid", "access_code"], name: "index_conferences_on_conf_sid_and_access_code", unique: true, using: :btree
    t.index ["start_time"], name: "index_conferences_on_start_time", using: :btree
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "name",       null: false
    t.string   "phone"
    t.string   "time_zone",  null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_contacts_on_user_id", using: :btree
  end

  create_table "recovery_tokens", force: :cascade do |t|
    t.string   "token",      null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_recovery_tokens_on_user_id", unique: true, using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                            null: false
    t.string   "phone",                           null: false
    t.string   "company"
    t.string   "time_zone",                       null: false
    t.string   "password_digest",                 null: false
    t.boolean  "active_user",     default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.datetime "expiration"
    t.index ["phone"], name: "index_users_on_phone", using: :btree
  end

end
