require 'fileutils'

require 'teracy-dev/processors/processor'
require 'teracy-dev/util'

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
        lookup_path = File.join(TeracyDev::BASE_DIR, kubespray['lookup_path'])
        path = File.join(lookup_path, 'kubespray')
        git = kubespray['location']['git']
        branch = kubespray['location']['branch']

        if File.exist? path
          # TODO: need to check and sync the state here when required
        else
          Dir.chdir(lookup_path) do
            @logger.info("cd #{lookup_path} && git clone #{git}")
            system("git clone #{git}")
          end

          Dir.chdir(path) do
            @logger.info("cd #{path} && git checkout #{branch}")
            system("git checkout #{branch}")
          end
        end
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
        end
      end

      def generate_nodes(k8s_config)
        num_instances = k8s_config['num_instances']
        instance_name_prefix = k8s_config['instance_name_prefix']
        vm_gui = k8s_config['vm_gui']
        vm_memory = k8s_config['vm_memory']
        vm_cpus = k8s_config['vm_cpus']
        network_mode = k8s_config['network']['mode']
        subnet = k8s_config['network']['subnet']
        os = k8s_config['os']
        network_plugin = k8s_config['network_plugin']
        etcd_instances = num_instances
        # The first two nodes are kube masters
        kube_master_instances = num_instances == 1 ? num_instances : (num_instances - 1)
        # All nodes are kube nodes
        kube_node_instances = num_instances
        local_release_dir = k8s_config['local_release_dir']
        host_vars = {}
        box = SUPPORTED_OS[os][:box]
        if SUPPORTED_OS[os].has_key? :box_url
          box_url = SUPPORTED_OS[os][:box_url]
        end
        kubespray_lookup_path = k8s_config['kubespray']['lookup_path']
        host_inventory = File.join(TeracyDev::BASE_DIR, 'workspace', 'inventory')
        nodes = []

        (1..num_instances).each do |i|
          vm_name = "%s-%02d" % [instance_name_prefix, i]
          ip = "#{subnet}.#{i+100}"
          host_vars[vm_name] = {
            "ip": ip,
            "bootstrap_os": SUPPORTED_OS[os][:bootstrap_os],
            "local_release_dir" => local_release_dir,
            "download_run_once": "False",
            "kube_network_plugin": network_plugin
          }
          node = {
            "_id" => "#{i-1}",
            "name" => vm_name,
            "vm" => {
              "box" => box,
              "box_url" => box_url,
              "hostname" => "#{vm_name}",
              "networks" => [{
                "_id" => "0",
                "mode" => network_mode,
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
                "playbook" => "#{kubespray_lookup_path}/kubespray/cluster.yml",
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
                "playbook" => "#{kubespray_lookup_path}/kubespray/cluster.yml",
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

