module OmniAuth
  module Strategies
    # The identity strategy allows you to provide simple internal
    # user authentication using the same process flow that you
    # use for external OmniAuth providers.
    class Identity
      include OmniAuth::Strategy

      option :fields, [:name, :email]
      option :on_login, nil
      option :on_registration, nil
      option :on_failed_registration, nil
      option :locate_conditions, ->(req) { { model.auth_key => req['auth_key'] } }

      def request_phase
        fail 'on_login not provided' unless options[:on_login]

        options[:on_login].call(env)
      end

      def callback_phase
        return fail!(:invalid_credentials) unless identity
        super
      end

      def other_phase
        if on_registration_path?
          if request.get?
            on_registration
          elsif request.post?
            registration_phase
          end
        else
          call_app!
        end
      end

      def on_registration
        fail 'on_registration not provided' unless options[:on_registration]
        options[:on_registration].call(env)
      end

      def registration_phase
        attributes = (options[:fields] + [:password, :password_confirmation]).inject({}) { |h, k| h[k] = request[k.to_s]; h }
        @identity = model.create(attributes)
        if @identity.persisted?
          env['PATH_INFO'] = callback_path
          callback_phase
        else
          if options[:on_failed_registration]
            env['omniauth.identity'] = @identity
            options[:on_failed_registration].call(env)
          else
            on_registration
          end
        end
      end

      uid { identity.uid }
      info { identity.info }

      def registration_path
        options[:registration_path] || "#{path_prefix}/#{name}/register"
      end

      def on_registration_path?
        on_path?(registration_path)
      end

      def identity
        if options.locate_conditions.is_a? Proc
          conditions = instance_exec(request, &options.locate_conditions)
          conditions.to_hash
        else
          conditions = options.locate_conditions.to_hash
        end
        @identity ||= model.authenticate(conditions, request['password'])
      end

      def model
        options[:model] || ::Identity
      end
    end
  end
end
