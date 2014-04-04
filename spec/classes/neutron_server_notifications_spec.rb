#
# Copyright (C) 2014 eNovance SAS and Authors <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for neutron::server::notifications class
#

require 'spec_helper'

describe 'neutron::server::notifications' do

  let :default_params do
    { :notify_nova_on_port_status_changes => true,
      :notify_nova_on_port_data_changes   => true,
      :send_events_interval               => '2',
      :nova_url                           => 'http://127.0.0.1:8774/v2',
      :nova_admin_auth_url                => 'http://localhost:5000/v2.0',
      :nova_admin_username                => 'nova',
      :nova_admin_tenant_name             => 'nova',
      :nova_region_name                   => 'RegionOne' }
  end

  let :params do
    { :nova_admin_password  => 'secrete' }
  end

  shared_examples_for 'neutron server notifications' do
    let :p do
      default_params.merge(params)
    end

    it 'configure neutron.conf' do
        should contain_neutron_config('DEFAULT/notify_nova_on_port_status_changes').with_value(true)
        should contain_neutron_config('DEFAULT/notify_nova_on_port_data_changes').with_value(true)
        should contain_neutron_config('DEFAULT/send_events_interval').with_value('2')
        should contain_neutron_config('DEFAULT/nova_url').with_value('http://127.0.0.1:8774/v2')
        should contain_neutron_config('DEFAULT/nova_admin_auth_url').with_value('http://localhost:5000/v2.0')
        should contain_neutron_config('DEFAULT/nova_admin_username').with_value('nova')
        should contain_neutron_config('DEFAULT/nova_admin_password').with_value('secrete')
        should contain_neutron_config('DEFAULT/nova_region_name').with_value('RegionOne')
        should contain_nova_admin_tenant_id_setter('nova_admin_tenant_id').with(
          :ensure      => 'present',
          :tenant_name => 'nova'
        )
    end

    context 'when overriding parameters' do
      before :each do
        params.merge!(
          :notify_nova_on_port_status_changes => false,
          :notify_nova_on_port_data_changes   => false,
          :send_events_interval               => '10',
          :nova_url                           => 'http://nova:8774/v3',
          :nova_admin_auth_url                => 'http://keystone:5000/v2.0',
          :nova_admin_username                => 'joe',
          :nova_region_name                   => 'MyRegion'
        )
      end
      it 'should configure neutron server with overrided parameters' do
        should contain_neutron_config('DEFAULT/notify_nova_on_port_status_changes').with_value(false)
        should contain_neutron_config('DEFAULT/notify_nova_on_port_data_changes').with_value(false)
        should contain_neutron_config('DEFAULT/send_events_interval').with_value('10')
        should contain_neutron_config('DEFAULT/nova_url').with_value('http://nova:8774/v3')
        should contain_neutron_config('DEFAULT/nova_admin_auth_url').with_value('http://keystone:5000/v2.0')
        should contain_neutron_config('DEFAULT/nova_admin_username').with_value('joe')
        should contain_neutron_config('DEFAULT/nova_admin_password').with_value('secrete')
        should contain_neutron_config('DEFAULT/nova_region_name').with_value('MyRegion')
      end
    end

    context 'when broken nova authentification' do
      before :each do
        params.merge!(
          :nova_admin_password => false
        )
      end
      it 'should fails to configure neutron server' do
          expect { subject }.to raise_error(Puppet::Error, /nova_admin_password must be set./)
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      {}
    end

    it_configures 'neutron server notifications'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      {}
    end

    it_configures 'neutron server notifications'
  end

end
