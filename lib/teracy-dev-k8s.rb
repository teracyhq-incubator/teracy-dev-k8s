require 'teracy-dev'

require_relative 'teracy-dev-k8s/processors/settings'

module TeracyDevK8s

  def self.init
    TeracyDev.register_processor(TeracyDevK8s::Processors::Settings.new)
  end

end
