Puppet::Type.type(:nova_admin_tenant_id_setter).provide(:ruby) do

  def exists?
    return false
  end

  def create
    config
  end

  def self.get_tenant_id(tenant_name)
    tenant = Puppet::Type.type('keystone_tenant').instances.find do |i|
      i.provider.name == tenant_name
    end
    if tenant
      return tenant.provider.id
    end
  end

  def get_tenant_id
    @tenant_id ||= self.class.get_tenant_id(@resource[:tenant_name])
  end

  def config
    Puppet::Type.type(:neutron_config).new(
      {:name => 'DEFAULT/nova_admin_tenant_id', :value => "#{get_tenant_id}"}
    ).create
  end

end
