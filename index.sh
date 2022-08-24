sudo apt-get update
sudo apt-get install nginx -y
echo "<h1>Welcome to Terraform ! AWS Infra created using Terraform</h1>" | sudo tee /var/www/html/index.html