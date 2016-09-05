require 'yaml'

$nodes_definition = "./nodes.yml"
$inventory_filename = nil

def readNodesDefinition()
  if ARGV.length==0 or ARGV[0]=='status'
    if ENV['NODES']==nil
      puts("Hint:")
      puts("You can use environment variable 'NODES' to specify another definition file, for example:")
      puts("  $ NODES=nodes-public.yml vagrant up")
      puts('=' * 60)
    end
  end

  if ENV['NODES']!=nil
    $nodes_definition = ENV['NODES']
  end

  puts("Nodes definition: #{ $nodes_definition }\n")

  filename = File.join(File.dirname(__FILE__), "../#{ $nodes_definition }")

  if !File.file?(filename)
    raise "Cannot find nodes definition file: #{ filename }\n"
  end

  basename = File.basename(filename, '.*')
  $inventory_filename = "ansible/#{ basename }"

  return YAML.load_file(filename)
end


def insertInventoryFile(file, machine_defines, node_type)
  machine_defines.each do |machine|
    if machine['node_type']==node_type
      line = machine['name'] + '     ansible_host=' + machine['network']['ip']
      file.puts line
    end
  end
end

def generateInventoryFile(machine_defines)
  if !File.file?($inventory_filename)
    puts "Ansible inventory-file not exist. New file created: #{ $inventory_filename }"
    inventory_file = File.open($inventory_filename, 'w')
    inventory_file.puts "[masters]"
    insertInventoryFile(inventory_file, machine_defines, 'master')

    inventory_file.puts "[slaves]"
    insertInventoryFile(inventory_file, machine_defines, 'slave')
    inventory_file.close
  else
    puts "Ansible inventory-file already exist: #{ $inventory_filename }"
  end
end
