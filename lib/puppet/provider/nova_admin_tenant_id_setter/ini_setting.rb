## NB: This must work with Ruby 1.8!

require 'rubygems'
require 'net/http'
require 'json'

# A custom exception class makes testing easier.
class KeystoneError < Puppet::Error
end

# Authenticates to a Keystone server and obtains an authentication token.
# It returns a 2-element +[token, authinfo]+, where +token+ is a token
# suitable for passing to openstack apis in the +X-Auth-Token+ header, and
# +authinfo+ is the complete response from Keystone, including the service
# catalog (if available).
#
# +auth_url+::
#   Keystone endpoint URL.  This function assumes API version
#   2.0 and an administrative endpoint, so this will typically look like
#   +http://somehost:35357/v2.0+.
#
# +username+::
#   Username for authentication.
#
# +password+::
#   Password for authentication
#
# +tenantID+::
#   Tenant UUID
#
# +tenantName+::
#   Tenant name
#
def keystone_v2_authenticate(auth_url,
                             username,
                             password,
                             tenantId=nil,
                             tenantName=nil)

    post_args = {
        'auth' => {
            'passwordCredentials' => {
                'username' => username,
                'password' => password
            },
        }}

    if tenantId
        post_args['auth']['tenantId'] = tenantId
    end

    if tenantName
        post_args['auth']['tenantName'] = tenantName
    end

    url = URI.parse("#{auth_url}/tokens")
    req = Net::HTTP::Post.new url.path
    req['content-type'] = 'application/json'
    req.body = post_args.to_json

    begin
        res = Net::HTTP.start(url.host, url.port) {|http|
            http.request(req)
        }

        if res.code != '200'
            raise KeystoneError, "Failed to authenticate to Keystone server at #{auth_url} as user #{username}."
        end
    rescue Errno::ECONNREFUSED
        raise KeystoneError, "Failed to connect to Keystone server at #{auth_url}."
    end

    data = JSON.parse res.body
    return data['access']['token']['id'], data
end

# Queries a Keystone server to a list of all tenants.
#
# +auth_url+::
#   Keystone endpoint.  See the notes for +auth_url+ in
#   +keystone_v2_authenticate+.
#
# +token+::
#   A Keystone token that will be passed in requests as the value of the
#   +X-Auth-Token+ header.
#
def keystone_v2_tenants(auth_url,
                        token)

    url = URI.parse("#{auth_url}/tenants")
    req = Net::HTTP::Get.new url.path
    req['content-type'] = 'application/json'
    req['x-auth-token'] = token

    begin
        res = Net::HTTP.start(url.host, url.port) {|http|
            http.request(req)
        }

        if res.code != '200'
            raise KeystoneError, "Failed to request list of tenants from Keystone server at #{auth_url}."
        end
    rescue Errno::ECONNREFUSED
        raise KeystoneError, "Failed to connect to Keystone server at #{auth_url}."
    end

    data = JSON.parse res.body
    data['tenants']
end

Puppet::Type.type(:nova_admin_tenant_id_setter).provide(:ruby) do
    def authenticate
        token, authinfo = keystone_v2_authenticate(
            @resource[:auth_url],
            @resource[:auth_username],
            @resource[:auth_password],
            nil,
            @resource[:auth_tenant_name])

        return token
    end

    def find_tenant_by_name (token)
        tenants  = keystone_v2_tenants(
            @resource[:auth_url],
            token)

        tenants.select{|tenant| tenant['name'] == @resource[:tenant_name]}
    end

    def exists?
        false
    end

    def create
        config
    end

    def get_tenant_id
        token = authenticate
        tenants = find_tenant_by_name(token)

        if tenants.length == 1
            return tenants[0]['id']
        elsif tenants.length > 1
            raise KeystoneError, 'Found multiple matches for tenant name'
        else
            raise KeystoneError, 'Unable to find matching tenant'
        end
    end

    def config
        Puppet::Type.type(:neutron_config).new(
            {:name => 'DEFAULT/nova_admin_tenant_id', :value => "#{get_tenant_id}"}
        ).create
    end

end

