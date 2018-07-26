# -*- mode: ruby -*-
# vi: set ft=ruby :

teracy_lib_dir = File.expand_path('../../../lib', __dir__)
$LOAD_PATH.unshift(teracy_lib_dir) unless $LOAD_PATH.include?(teracy_lib_dir)

k8s_setup_lib_dir = File.expand_path('./lib', __dir__)
$LOAD_PATH.unshift(k8s_setup_lib_dir) unless $LOAD_PATH.include?(k8s_setup_lib_dir)


require 'teracy-dev'
require 'teracy-dev-k8s'

logger = TeracyDev::Logging.logger_for("dev-setup")


TeracyDev.register_processor(TeracyDevK8s::SettingsProcessor.new)
