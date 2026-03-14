#!/bin/bash

# ============================================================
# Glagol VPN Server Setup Script
# Created by: مهندس مصطفي أيوب
# Contact: +79891574730 | mostafaayoub1210@mail.ru
# ============================================================

set -e

echo "🚀 Glagol VPN Server Setup"
echo "Developer: مهندس مصطفي أيوب"
echo "Contact: mostafaayoub1210@mail.ru"
echo "================================"

# Update system
echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# Install WireGuard
echo "🔧 Installing WireGuard..."
sudo apt install wireguard -y

# Install UFW firewall
echo "🛡️ Installing firewall..."
sudo apt install ufw -y

# Enable IP forwarding
echo "🌐 Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 51820/udp
sudo ufw --force enable

# Create WireGuard directory
echo "📁 Creating WireGuard directory..."
sudo mkdir -p /etc/wireguard

# Generate server keys
echo "🔑 Generating server keys..."
sudo wg genkey | sudo tee /etc/wireguard/server_private.key
sudo chmod 600 /etc/wireguard/server_private.key
sudo wg pubkey < /etc/wireguard/server_private.key | sudo tee /etc/wireguard/server_public.key

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)
echo "🌍 Server IP: $SERVER_IP"

# Create WireGuard configuration
echo "⚙️ Creating WireGuard configuration..."
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = $(sudo cat /etc/wireguard/server_private.key)
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Client 1 - مهندس مصطفي أيوب
PublicKey = $(wg genkey | wg pubkey > /tmp/client1.pub && cat /tmp/client1.pub)
AllowedIPs = 10.8.0.2/32
EOF

# Start WireGuard
echo "🚀 Starting WireGuard..."
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0

# Create client configuration
echo "📱 Creating client configuration..."
SERVER_PUBLIC_KEY=$(sudo cat /etc/wireguard/server_public.key)
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

mkdir -p ~/glagol_vpn_configs
cat > ~/glagol_vpn_configs/moustafa_client.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 1.1.1.1, 8.8.8.8
MTU = 1420

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# Update server configuration with client public key
sudo sed -i "s/PublicKey = $(cat /tmp/client1.pub)/PublicKey = $CLIENT_PUBLIC_KEY/" /etc/wireguard/wg0.conf
sudo wg-quick down wg0
sudo wg-quick up wg0

# Install monitoring
echo "📊 Installing monitoring..."
sudo apt install htop iotop -y

# Create status script
echo "📈 Creating status script..."
sudo tee /usr/local/bin/vpn-status > /dev/null <<'EOF'
#!/bin/bash
echo "🔥 Glagol VPN Status"
echo "Developer: مهندس مصطفي أيوب"
echo "=================="
echo "Server IP: $(curl -s ifconfig.me)"
echo "WireGuard Status:"
sudo wg show
echo "Connected Peers:"
sudo wg show wg0 peers
echo "=================="
EOF

sudo chmod +x /usr/local/bin/vpn-status

# Setup complete
echo "✅ Setup complete!"
echo "📞 Developer: مهندس مصطفي أيوب"
echo "📧 Contact: mostafaayoub1210@mail.ru"
echo "📱 Phone: +79891574730"
echo ""
echo "🔧 Commands:"
echo "  vpn-status - Show VPN status"
echo "  sudo wg show - Show WireGuard status"
echo "  sudo wg-quick down wg0 - Stop VPN"
echo "  sudo wg-quick up wg0 - Start VPN"
echo ""
echo "📁 Client config: ~/glagol_vpn_configs/moustafa_client.conf"
echo "🌍 Server IP: $SERVER_IP"
echo "📞 Support: +79891574730"
echo ""
echo "🎉 Glagol VPN server is ready!"
