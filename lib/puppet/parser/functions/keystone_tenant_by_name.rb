require 'fog'

module Puppet::Parser::Functions

    newfunction(:keystone_tenant_by_name, :type => :rvalue) do |args|
        auth_url = args[0]
        username = args[1]
        password = args[2]
        tenant_name = args[3]

        keystone = Fog::Identity.new :provider => 'OpenStack',
                                     :openstack_auth_url => auth_url,
                                     :openstack_username => username,
                                     :openstack_api_key => password


        tenant = keystone.tenants.find{ |t| t.name == tenant_name }
        tenant.id
    end

end

