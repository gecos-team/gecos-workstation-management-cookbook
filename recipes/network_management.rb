
gecos_ws_management_setup_connection "vpn-user1" do
  network_type "vpn"
  cert "file:///kkfuti"
  user "user1"
end

gecos_ws_management_setup_connection "eth0-default" do
  network_type "wired"
  use_dhcp true
end
