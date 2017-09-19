class RecoveryToken < ApplicationRecord
	belongs_to :user
	validates_presence_of :user
	validates_uniqueness_of :user
	validates :token, presence: true
end
