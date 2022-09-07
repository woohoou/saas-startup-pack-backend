module Users
  class RegistrationsController < Devise::RegistrationsController
    skip_forgery_protection if: -> { request.format.json? }
    before_action :configure_sign_up_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]
    respond_to :json

    include Tokenable

    # POST /users
    def create
      if !sign_up_params[:email].present? && sign_up_params[:phone_number].present?
        create_resource_with_phone_number(sign_up_params)
      else
        build_resource(sign_up_params)
        resource.save
      end
      
      yield resource if block_given?
      if resource.persisted?
        if resource.auth_by_phone_number?
          respond_with(User.new({ phone_number: resource.phone_number }), location: after_sign_up_path_for(resource))
        elsif resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)

          # Generate access token for json request
          if request.format.json? && resource.email_required?
            get_credentials.each do |header, value|
              response.set_header(header.to_s.titleize.gsub(' ', '-'), value)
            end
          end
          respond_with(resource, location: after_sign_up_path_for(resource))
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    # PUT /resource
    # We need to use a copy of the resource because we don't want to change
    # the current user in place.
    def update
      prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

      resource_updated = if resource.current_password_required?
        resource.update_with_password(account_update_params)
      else
        resource.update(account_update_params)
      end
      yield resource if block_given?
      if resource_updated
        set_flash_message_for_update(resource, prev_unconfirmed_email)
        bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

        if request.format.json? && resource.email_required?
          respond_with(resource, location: after_sign_up_path_for(resource))
        else
          respond_with(resource, location: after_update_path_for(resource))
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    protected

    def create_resource_with_phone_number(sign_up_params)
      self.resource = self.resource_class.create_with(sign_up_params.except(:phone_number)).find_or_create_by(phone_number: sign_up_params[:phone_number])
    end
    
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :username, :terms_accepted])
    end

    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :username, :email])
    end

    # Authenticates the current scope and gets the current resource from the session or token.
    def authenticate_scope!
      self.resource = if request.format.json? && doorkeeper_token && valid_doorkeeper_token?
        User.find(doorkeeper_token.resource_owner_id)
      else
        send(:"authenticate_#{resource_name}!", force: true)
        send(:"current_#{resource_name}")
      end  
    end
  end
end