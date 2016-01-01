require 'omniauth'

module OmniAuth
  module Strategies
    autoload :Identity, 'omniauth/strategies/identity'
  end

  module Identity
    autoload :Model, 'omniauth/identity/model'
    module Models
      autoload :ActiveRecord, 'omniauth/identity/models/active_record'
    end
  end
end
