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
    req = Net::HTTP::Post.new url
    req['content-type'] = 'application/json'
    req.body = post_args.to_json

    res = Net::HTTP.start(url.hostname, url.port) {|http|
        http.request(req)
    }

    data = JSON.parse res.body
    return data['access']['token']['id'], data
end

def keystone_v2_tenants(auth_url,
                        token)

    url = URI.parse("#{auth_url}/tenants")
    req = Net::HTTP::Get.new url
    req['content-type'] = 'application/json'
    req['x-auth-token'] = token

    res = Net::HTTP.start(url.hostname, url.port) {|http|
        http.request(req)
    }

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

