Puppet::Type.newtype(:nova_admin_tenant_id_setter) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the setting to update.'
  end

  newparam(:tenant_name) do
    desc 'The nova admin tenant name.'
  end

end
