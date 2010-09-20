##
#  Locates gems that conform to Radiant extensions. We can't let Rails treat
#  these as regular Rails::GemPlugins, because then they are handled as engines
#  and engine load paths are always lowest priority. Extension load paths
#  need to be higher than Radiant's own.

module Radiant
  class ExtensionLocator < Rails::Plugin::GemLocator
    def plugins
      all_gems = initializer.configuration.gems
      all_gems += Bundler.load.dependencies_for(:default, Rails.env).map{|dep| Rails::GemDependency.new(dep.name, :requirement => dep.requirement)} if defined?(Bundler)
      gem_index = all_gems.inject({}) { |memo, gem| memo.update gem.specification => gem }

      specs = gem_index.keys.select do |spec|
        spec && spec.loaded_from && spec.name =~ /^radiant-.*-extension$/
      end.compact

      require "rubygems/dependency_list"

      deps = Gem::DependencyList.new
      deps.add(*specs) unless specs.empty?

      deps.dependency_order.collect do |spec|
        ExtensionGem.new(spec, gem_index[spec])
      end
    end
  end
end
