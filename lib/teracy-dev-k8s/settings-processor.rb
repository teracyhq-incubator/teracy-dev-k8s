require 'teracy-dev/processors/processor'
require 'teracy-dev/util'

module TeracyDevK8s
  class SettingsProcessor < TeracyDev::Processors::Processor
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
      @logger.debug(settings)

      k8sConfig = settings['k8s']

      @num_instances = k8sConfig['num_instances']
      @instance_name_prefix = k8sConfig['instance_name_prefix']
      @vm_gui = k8sConfig['vm_gui']
      @vm_memory = k8sConfig['vm_memory']
      @vm_cpus = k8sConfig['vm_cpus']
      @subnet = k8sConfig['subnet']
      @os = k8sConfig['os']
      @network_plugin = k8sConfig['network_plugin']
      @etcd_instances = @num_instances
      # The first two nodes are kube masters
      @kube_master_instances = @num_instances == 1 ? @num_instances : (@num_instances - 1)
      # All nodes are kube nodes
      @kube_node_instances = @num_instances
      @local_release_dir = k8sConfig['local_release_dir']
      @host_vars = {}
      @box = SUPPORTED_OS[@os][:box]
      if SUPPORTED_OS[@os].has_key? :box_url
        @box_url = SUPPORTED_OS[$os][:box_url]
      end
      inventory()

      # generate teracy-dev settings basing on k8s config
      nodes = generate_nodes(settings['k8s'])

      settings["nodes"] = nodes
      settings
    end

    private

    def inventory
      inventory = File.join(File.dirname(__FILE__), "../../../", "kubespray", "inventory", "sample")

      vagrant_ansible = File.join(File.dirname(__FILE__), "../../../../", ".vagrant",
                           "provisioners", "ansible")
      FileUtils.mkdir_p(vagrant_ansible) if ! File.exist?(vagrant_ansible)
      if !File.exist?(File.join(vagrant_ansible, "inventory"))
        FileUtils.ln_s(inventory, File.join(vagrant_ansible, "inventory"))
      end
    end

    def generate_nodes(k8sConfig)
      nodes = []

      (1..@num_instances).each do |i|
        vm_name = "%s-%02d" % [@instance_name_prefix, i]
        ip = "#{@subnet}.#{i+100}"
        @host_vars[vm_name] = {
          "ip": ip,
          "bootstrap_os": SUPPORTED_OS[@os][:bootstrap_os],
          "local_release_dir" => @local_release_dir,
          "download_run_once": "False",
          "kube_network_plugin": @network_plugin
        }
        node = {
          "_id" => "#{i-1}",
          "name" => vm_name,
          "vm" => {
            "box" => @box,
            "box_url" => @box_url,
            "hostname" => "#{vm_name}", #.local
            "networks" => [{
              "_id" => "0",
              "ip" => ip
            }]
          },
          "ssh" => {
            "username" => SUPPORTED_OS[@os][:user]
          },
          "providers" => [{
            "_id" => "0",
            "gui" => @vm_gui,
            "memory" => @vm_memory,
            "cpus" => @vm_cpus
          }]
        }
        # Only execute once the Ansible provisioner,
        # when all the machines are up and ready.
        if i == @num_instances
          provisioner = {
            "_id" => "1",
            "raw_arguments" => ["--forks=#{@num_instances}", "--flush-cache"],
            "host_vars" => @host_vars,
            "groups" => {
              "etcd" => ["#{@instance_name_prefix}-0[1:#{@etcd_instances}]"],
              "kube-master" => ["#{@instance_name_prefix}-0[1:#{@kube_master_instances}]"],
              "kube-node" => ["#{@instance_name_prefix}-0[1:#{@kube_node_instances}]"],
              "k8s-cluster:children" => ["kube-master", "kube-node"],
            }
          }
          node["provisioners"] = [provisioner]
        end

        default_node = k8sConfig['default_node']
        @logger.debug("default_node: #{default_node}")
        @logger.debug("node: #{node}")

        merged_node = TeracyDev::Util.override(k8sConfig['default_node'], node)
        nodes << merged_node
      end
      @logger.debug("nodes: #{nodes}")
      nodes
    end

  end
end
