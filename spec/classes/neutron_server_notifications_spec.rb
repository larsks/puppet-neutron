require 'spec_helper'

describe 'neutron::server::notifications' do
    let :pre_condition do
        # We need the keystone_user resource type defined due to the
        # dependency in manifests/server/notifications.pp
        'define keystone_user ($name) {}'
    end

    let :default_params do
        {
            :nova_admin_password => 'secret',
        }
    end

    context 'when admin_id is specified' do
        let :params do
            default_params.merge({
                :nova_admin_auth_url => 'http://badserver:35357/v2.0',
                :nova_admin_tenant_id => 'ADMIN-ID',
            })
        end

        it { should_not contain_notify('lookup') }
    end

    # This should call the custom provider, but even though an appropriate
    # resource types seems to exist the provider is never being called.
    context 'when admin_id is not specified' do
        let :params do
            default_params.merge({
                :nova_admin_auth_url => 'http://badserver:35357/v2.0',
            })
        end

        it { should contain_notify('lookup') }
        it { should contain_nova_admin_tenant_id_setter('nova_admin_tenant_id') }
    end

end
