#
# Cookbook Name:: safe_search
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute

safe_search(:node,
            '*:*',
            filter_result: { 'name' => ['name'] },
            threshold: 80
           ) do |node|
  Chef::Log.warn("safe_search found node: #{node['name']}")
end

search(:node) do |node|
  Chef::Log.warn("normal search found node: #{node.name}")
end
