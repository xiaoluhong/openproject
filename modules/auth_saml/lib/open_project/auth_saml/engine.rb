require 'omniauth-saml'
module OpenProject
  module AuthSaml
    class Engine < ::Rails::Engine
      engine_name :openproject_auth_saml

      include OpenProject::Plugins::ActsAsOpEngine
      extend OpenProject::Plugins::AuthPlugin

      register 'openproject-auth_saml',
               author_url: 'https://github.com/finnlabs/openproject-auth_saml',
               bundled: true

      assets %w(
        auth_saml/**
        auth_provider-saml.png
      )

      config.after_initialize do
        # Automatically update the openproject user whenever their info change in the upstream identity provider
        OpenProject::OmniAuth::Authorization.after_login do |user, auth_hash, context|
          # see https://github.com/opf/openproject/blob/caa07c5dd470f82e1a76d2bd72d3d55b9d2b0b83/app/controllers/concerns/omniauth_login.rb#L148
          attributes = context.send(:omniauth_hash_to_user_attributes, auth_hash) || {}
          attributes = attributes.with_indifferent_access

          # Don't allow unsetting admin if user is already admin
          attributes.delete(:admin) if user.admin?

          user.update attributes
        end
      end

      register_auth_providers do
        configuration = if OpenProject::Configuration['saml'].present?
                          Rails.logger.info("[auth_saml] Registering saml integration from configuration.yml")

                          OpenProject::Configuration['saml']
                        elsif (settings = Rails.root.join('config', 'plugins', 'auth_saml', 'settings.yml')).exist?
                          Rails.logger.info("[auth_saml] Registering saml integration from settings file")

                          YAML::load(File.open(settings)).symbolize_keys
                        end

        if configuration
          strategy :saml do
            configuration.values.map do |h|
              h[:openproject_attribute_map] = Proc.new do |auth|
                {
                  login: auth[:uid],
                  admin: (auth.info['admin'].to_s.downcase == "true")
                }
              end
              h.symbolize_keys
            end
          end
        end
      end
    end
  end
end
