cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "/Library/Application Support/SpechtLite/"
sudo cp ProxyConfig "/Library/Application Support/SpechtLite/"
sudo chown root:admin "/Library/Application Support/SpechtLite/ProxyConfig"
sudo chmod +s "/Library/Application Support/SpechtLite/ProxyConfig"

echo done
