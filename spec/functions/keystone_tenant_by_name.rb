require 'spec_helper'

auth_response = {
    'access' => {
        'token' => {
            'id' => 'TOKEN',
        }
    }
}

tenants_response = {
    'tenants' => [
        { 'name' => 'admin',
          'id' => 'ADMIN_ID' },
          { 'name' => 'target_tenant',
            'id' => 'TARGET_ID' },
    ]
}

good_auth_request = { 
    'auth' => {
        'passwordCredentials' => {
            'username' => 'admin_user',
            'password' => 'admin_password',
        },
        'tenantName' => 'admin_tenant',
    }
}

bad_auth_request = { 
    'auth' => {
        'passwordCredentials' => {
            'username' => 'admin_user',
            'password' => 'not_the_admin_password',
        },
        'tenantName' => 'admin_tenant',
    }
}

describe 'keystone_tenant_by_name' do
    let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

    it "should exist" do
        Puppet::Parser::Functions.function("keystone_tenant_by_name").should == "function_keystone_tenant_by_name"
    end

    before :each do
        stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
            with(:body => good_auth_request.to_json).
            to_return(:status => 200, :body => auth_response.to_json, :headers => {})

        stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
            with(:body => bad_auth_request.to_json).
            to_return(:status => 401, :body => "", :headers => {})

        stub_request(:get, "http://127.0.0.1:35357/v2.0/tenants").
            with(:headers => {'X-Auth-Token'=>'TOKEN'}).
            to_return(:status => 200, :body => tenants_response.to_json, :headers => {})

    end

    it "should fail with a bad password" do
        expect {
            result = scope.function_keystone_tenant_by_name [
                'http://127.0.0.1:35357/v2.0',
                'admin_user',
                'not_the_admin_password',
                'admin_tenant',
                'target_tenant']
        }.to raise_error(KeystoneError, /Failed to authenticate to Keystone server/)
    end

    it "should return a tenant id" do
        result = scope.function_keystone_tenant_by_name [
                'http://127.0.0.1:35357/v2.0',
                'admin_user',
                'admin_password',
                'admin_tenant',
                'target_tenant']

        expect(result).to eq("TARGET_ID")
    end

end

describe 'keystone_tenant_by_name' do
    let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

    before :each do
        stub_request(:any, "http://127.0.0.1:35357/v2.0/tokens").to_raise(Errno::ECONNREFUSED)
    end

    it "should fail with connection error" do
        expect {
            result = scope.function_keystone_tenant_by_name [
                'http://127.0.0.1:35357/v2.0',
                'admin_user',
                'not_the_admin_password',
                'admin_tenant',
                'target_tenant']
        }.to raise_error(KeystoneError, /Failed to connect to Keystone server/)
    end
end

