require 'mongoid'

module OmniAuth
  module Identity
    module Models
      module Mongoid

        def self.included(base)

          base.class_eval do

            include ::OmniAuth::Identity::Model
            include ActiveModel::SecurePassword

            field :password_digest, type: String

            has_secure_password(validations: false)

            # from has ActiveModel::SecurePassword
            include ActiveModel::Validations

            # This ensures the model has a password by checking whether the password_digest
            # is present, so that this works with both new and existing records. However,
            # when there is an error, the message is added to the password attribute instead
            # so that the error message will make sense to the end-user.
            validate do |record|
              record.errors.add(:password, :blank) if record.provider == "identity" and not record.send("#{:password}_digest").present?
            end

            validates_length_of :password, maximum: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED, if: Proc.new {|record| record.provider == "identity" }
            validates_confirmation_of :password, allow_blank: true, if: Proc.new {|record| record.provider == "identity" }

            def self.auth_key=(key)
              super
              validates_uniqueness_of key, :case_sensitive => false
            end

            def self.locate(search_hash)
              where(search_hash).first
            end
          end
        end
      end
    end
  end
end
