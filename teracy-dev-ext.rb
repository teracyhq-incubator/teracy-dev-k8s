
k8s_setup_lib_dir = File.expand_path('./lib', __dir__)
$LOAD_PATH.unshift(k8s_setup_lib_dir) unless $LOAD_PATH.include?(k8s_setup_lib_dir)


require 'teracy-dev'
require 'teracy-dev-k8s'

TeracyDev.register_processor(TeracyDevK8s::Processors::Settings.new)
