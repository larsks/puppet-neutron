require 'puppet'
require 'puppet/type/nova_admin_tenant_id_setter'

describe 'Puppet::Type.type(:nova_admin_tenant_id_setter)' do
  it 'should require a name' do
    expect {
      Puppet::Type.type(:nova_admin_tenant_id_setter).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  before :each do
    @nova_admin_tenant_id_setter = Puppet::Type.type(:nova_admin_tenant_id_setter).new(
      :name        => 'nova_admin_tenant_id',
      :tenant_name => 'admin')
  end

  it 'should accept valid ensure values' do
    @nova_admin_tenant_id_setter[:ensure] = :present
    @nova_admin_tenant_id_setter[:ensure].should == :present
    @nova_admin_tenant_id_setter[:ensure] = :absent
    @nova_admin_tenant_id_setter[:ensure].should == :absent
  end

  it 'should not accept invalid ensure values' do
    expect {
      @nova_admin_tenant_id_setter[:ensure] = :installed
    }.to raise_error(Puppet::Error, /Invalid value/)
  end
end
