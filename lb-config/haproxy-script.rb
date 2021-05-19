require 'aws-sdk'

# We use instance profile credentials to authenticate
# using the role attached to the instance
region = "us-east-1"
auto_scaling_group = "auto-scaling-proyecto2"
credentials = Aws::InstanceProfileCredentials.new

Aws.config.update(credentials: credentials)
Aws.config.update(region: region)

autoscaling = Aws::AutoScaling::Client.new(region: region)
ec2 = Aws::EC2::Client.new(region: region)

# Retrieve current autoscaling group instances
response = autoscaling.describe_auto_scaling_groups(auto_scaling_group_names: [auto_scaling_group])
instances = response.auto_scaling_groups.first.instances

hosts = []
instances.each do |instance|
  if instance.lifecycle_state == "InService"
    # We cannot access the private IP address of the
    # instance using Autoscaling API, so we have to
    # retrieve the instance object from the EC2 API.
    ec2_instance = ec2.describe_instances(instance_ids: [instance.instance_id]).reservations.first.instances.first
    if ec2_instance.state.name == "running"
      hosts << {ip: ec2_instance.private_ip_address, public_name: ec2_instance.public_dns_name}
    end
  end
end

# Copy template config to the config file
# and append hosts to backend configuration
FileUtils.cp("/etc/haproxy/haproxy.cfg.template", "/etc/haproxy/haproxy.cfg")

server_count = 0
open("/etc/haproxy/haproxy.cfg", "a") do |f|
  hosts.each do |host|
    server_count += 1
    f << "\tserver srvr#{server_count} #{host[:ip]}:80\n"
  end
end

# Reload HAProxy with system command
stdout = `service haproxy reload`
puts " -> reloaded HAProxy: #{stdout}"

