require 'fileutils'

require 'teracy-dev'
require 'teracy-dev/processors/processor'
require 'teracy-dev/util'
require 'teracy-dev/location/manager'

module TeracyDevK8s
  module Processors
    class Settings < TeracyDev::Processors::Processor
      COREOS_URL_TEMPLATE = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json"

      SUPPORTED_OS = {
        "coreos-stable" => {box: "coreos-stable",      bootstrap_os: "coreos", user: "core", box_url: COREOS_URL_TEMPLATE % ["stable"]},
        "coreos-alpha"  => {box: "coreos-alpha",       bootstrap_os: "coreos", user: "core", box_url: COREOS_URL_TEMPLATE % ["alpha"]},
        "coreos-beta"   => {box: "coreos-beta",        bootstrap_os: "coreos", user: "core", box_url: COREOS_URL_TEMPLATE % ["beta"]},
        "ubuntu"        => {box: "bento/ubuntu-16.04", bootstrap_os: "ubuntu", user: "vagrant"},
        "centos"        => {box: "centos/7",           bootstrap_os: "centos", user: "vagrant"},
        "opensuse"      => {box: "opensuse/openSUSE-42.3-x86_64", bootstrap_os: "opensuse", use: "vagrant"},
        "opensuse-tumbleweed" => {box: "opensuse/openSUSE-Tumbleweed-x86_64", bootstrap_os: "opensuse", use: "vagrant"},
      }

      def process(settings)

        k8s_config = settings['teracy-dev-k8s']
        @logger.debug("k8s_config: #{k8s_config}")

        # guest mode currently supports only 1 node
        if k8s_config['ansible']['mode'] == 'guest' and k8s_config['num_instances'] > 1
          @logger.error("ansible guest mode supports only 1 num_instances, you need to use 'host' mode instead")
          @logger.error("and follow: https://github.com/kubernetes-incubator/kubespray#vagrant")
          abort
        end

        setup(k8s_config)

        nodes = generate_nodes(k8s_config)
        @logger.debug("nodes: #{nodes}")
        #abort
        # should override
        TeracyDev::Util.override(settings, {"nodes" => nodes})
      end

      private

      def setup(k8s_config)
        sync_kubespray(k8s_config['kubespray'])
        setup_inventory(k8s_config)
      end

      def sync_kubespray(kubespray)
        lookup_path = File.join(TeracyDev::BASE_DIR, kubespray['lookup_path'] ||= TeracyDev::DEFAULT_EXTENSION_LOOKUP_PATH)
        path = File.join(lookup_path, 'kubespray')
        kubespray['location'].merge!({
          "lookup_path" => lookup_path,
          "path" => path
        })
        sync_existing = kubespray['lookup_path'] == TeracyDev::DEFAULT_EXTENSION_LOOKUP_PATH
        TeracyDev::Location::Manager.sync(kubespray['location'], sync_existing)
      end

      def setup_inventory(k8s_config)
        kubespray = k8s_config['kubespray']
        # copy the sample inventory to `workspace/inventory` if not exists yet and we can configure anything there
        src_inventory = File.join(TeracyDev::BASE_DIR, kubespray['lookup_path'], "kubespray", "inventory", "sample", ".")
        dest_inventory = File.join(TeracyDev::BASE_DIR, 'workspace', 'inventory')
        if !File.exists? File.join(dest_inventory)
          @logger.info("cp -r #{src_inventory} #{dest_inventory}")
          FileUtils.mkdir_p dest_inventory
          FileUtils.cp_r src_inventory, dest_inventory
        end

        if k8s_config['ansible']['mode'] == "host"
          vagrant_ansible = File.join(TeracyDev::BASE_DIR, ".vagrant", "provisioners", "ansible")
          FileUtils.mkdir_p(vagrant_ansible) if !File.exist?(vagrant_ansible)
          if !File.exist?(File.join(vagrant_ansible, "inventory"))
            FileUtils.ln_s(dest_inventory, File.join(vagrant_ansible, "inventory"))
          end
          # delelete #{dest_inventory}/vagrant_ansible_local_inventory if generated on "guest" mode
          guest_generated_file_path = File.join("#{dest_inventory}", "vagrant_ansible_local_inventory")
          FileUtils.remove_file(guest_generated_file_path) if File.exist? guest_generated_file_path
        elsif k8s_config['ansible']['mode'] == "guest"
          # delelete #{dest_inventory}/vagrant_ansible_inventory if generated on "host" mode
          host_generated_file_path = File.join("#{dest_inventory}", "vagrant_ansible_inventory")
          FileUtils.remove_file(host_generated_file_path) if File.exist? host_generated_file_path
        end
      end

      def generate_nodes(k8s_config)
        num_instances = k8s_config['num_instances']
        instance_name_prefix = k8s_config['instance_name_prefix']
        vm_gui = k8s_config['vm_gui']
        vm_memory = k8s_config['vm_memory']
        vm_cpus = k8s_config['vm_cpus']
        network_type = k8s_config['network']['type']
        subnet = k8s_config['network']['subnet']
        os = k8s_config['os']
        network_plugin = k8s_config['network_plugin']
        etcd_instances = num_instances
        # The first two nodes are kube masters
        kube_master_instances = num_instances == 1 ? num_instances : (num_instances - 1)
        # All nodes are kube nodes
        kube_node_instances = num_instances
        ansible_host_vars = k8s_config['ansible']['host_vars']
        local_release_dir = k8s_config['local_release_dir']
        host_vars = {}
        box = SUPPORTED_OS[os][:box]
        if SUPPORTED_OS[os].has_key? :box_url
          box_url = SUPPORTED_OS[os][:box_url]
        end
        kubespray_lookup_path = k8s_config['kubespray']['lookup_path']
        host_inventory = File.join(TeracyDev::BASE_DIR, 'workspace', 'inventory')
        nodes = []
        playbook_path = k8s_config['ansible']['playbook_path']
        if playbook_path.start_with? "/"
          playbook_path = File.join(TeracyDev::BASE_DIR, playbook_path)
        else
          playbook_path = File.join(kubespray_lookup_path, 'kubespray', playbook_path)
        end
        @logger.debug("playbook_path: #{playbook_path}")

        (1..num_instances).each do |i|
          vm_name = "%s-%02d" % [instance_name_prefix, i]
          ip = "#{subnet}.#{i+100}"
          host_vars[vm_name] = {
            "ip": ip,
            "bootstrap_os": SUPPORTED_OS[os][:bootstrap_os]
          }

          host_vars[vm_name].merge!(ansible_host_vars)
          @logger.debug("host_vars[#{vm_name}]: #{host_vars[vm_name]}")

          node = {
            "_id" => "#{i-1}",
            "name" => vm_name,
            "vm" => {
              "box" => box,
              "box_url" => box_url,
              "hostname" => "#{vm_name}",
              "networks" => [{
                "_id" => "0",
                "type" => network_type,
                "ip" => ip
              }]
            },
            "ssh" => {
              "username" => SUPPORTED_OS[os][:user]
            },
            "providers" => [{
              "_id" => "0",
              "gui" => vm_gui,
              "memory" => vm_memory,
              "cpus" => vm_cpus
            }]
          }

          # Only execute once the Ansible provisioner,
          # when all the machines are up and ready.
          if i == num_instances

            if k8s_config['ansible']['mode'] == 'guest'
              provisioner = {
                "_id" => "k8s-1",
                "type" => "ansible_local",
                "enabled" => true,
                "playbook" => "#{playbook_path}",
                "config_file" => "#{kubespray_lookup_path}/kubespray/ansible.cfg",
                "become" => true,
                "limit" => "all",
                "raw_arguments" => ["--forks=#{num_instances}", "--flush-cache"],
                "host_vars" => host_vars,
                "verbose" => k8s_config['ansible']['verbose'],
                "install_mode" => "pip_args_only",
                "pip_args" => "-r /vagrant/#{kubespray_lookup_path}/kubespray/requirements.txt",
                "groups" => {
                  "etcd" => ["#{instance_name_prefix}-0[1:#{etcd_instances}]"],
                  "kube-master" => ["#{instance_name_prefix}-0[1:#{kube_master_instances}]"],
                  "kube-node" => ["#{instance_name_prefix}-0[1:#{kube_node_instances}]"],
                  "k8s-cluster:children" => ["kube-master", "kube-node"],
                }
              }
              node["provisioners"] = [provisioner]
              # map example inventory to /tmp/vagrant-ansible/inventory with the guest
              node['vm']['synced_folders'] = [{
                "_id" => "k8s-0",
                "type" => "virtualbox",
                "host" => "#{host_inventory}",
                "guest" => "/tmp/vagrant-ansible/inventory/"
              }]
            elsif k8s_config['ansible']['mode'] == 'host'
              provisioner = {
                "_id" => "k8s-1",
                "type" => "ansible",
                "enabled" => true,
                "playbook" => "#{playbook_path}",
                "config_file" => "#{kubespray_lookup_path}/kubespray/ansible.cfg",
                "become" => true,
                "limit" => "all",
                "host_key_checking" => false,
                "raw_arguments" => ["--forks=#{num_instances}", "--flush-cache"],
                "host_vars" => host_vars,
                "verbose" => k8s_config['ansible']['verbose'],
                "groups" => {
                  "etcd" => ["#{instance_name_prefix}-0[1:#{etcd_instances}]"],
                  "kube-master" => ["#{instance_name_prefix}-0[1:#{kube_master_instances}]"],
                  "kube-node" => ["#{instance_name_prefix}-0[1:#{kube_node_instances}]"],
                  "k8s-cluster:children" => ["kube-master", "kube-node"],
                }
              }
              if File.exist?(File.join(host_inventory, "hosts"))
                provisioner["inventory_path"] = host_inventory
              end
              node["provisioners"] = [provisioner]
            end
          end

          node_template = k8s_config['node_template']
          # @logger.debug("node_template: #{node_template}")
          @logger.debug("generate_nodes: node: #{node}")
          nodes << TeracyDev::Util.override(node_template, node)
        end
        nodes
      end

    end
  end
end

