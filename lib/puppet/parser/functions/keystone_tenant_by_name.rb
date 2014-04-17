## NB: This must work with Ruby 1.8!

require 'rubygems'
require 'net/http'
require 'json'

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
            raise Puppet::Error, "Failed to authenticate to Keystone server at #{auth_url} as user #{username}."
        end
    rescue Errno::ECONNREFUSED
        raise Puppet::Error, "Failed to connect to Keystone server at #{auth_url}."
    end

    data = JSON.parse res.body
    return data['access']['token']['id'], data
end

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
            raise Puppet::Error, "Failed to request list of tenants from Keystone server at #{auth_url}."
        end
    rescue Errno::ECONNREFUSED
        raise Puppet::Error, "Failed to connect to Keystone server at #{auth_url}."
    end

    data = JSON.parse res.body
    data['tenants']
end

module Puppet::Parser::Functions

    newfunction(:keystone_tenant_by_name, :type => :rvalue) do |args|
        auth_url = args[0]
        auth_username = args[1]
        auth_password = args[2]
        auth_tenant_name = args[3]
        tenant_name = args[4]

        token, authinfo = keystone_v2_authenticate(auth_url,
                                                   auth_username,
                                                   auth_password,
                                                   nil,
                                                   auth_tenant_name)
        tenants = keystone_v2_tenants(auth_url, token)
        selected = tenants.select{|tenant| tenant['name'] == tenant_name}

        return selected.length == 1 ? selected[0]['id'] : nil
    end

end

