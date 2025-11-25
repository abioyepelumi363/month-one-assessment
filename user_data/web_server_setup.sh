#!/bin/bash
yum update -y
yum install -y httpd

INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)
PRIVATE_IP=$(ec2-metadata --local-ipv4 | cut -d " " -f 2)
PUBLIC_IP=$(ec2-metadata --public-ipv4 | cut -d " " -f 2 2>/dev/null || echo "N/A")

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Web Server</title>
</head>
    <body>
    <div class="container">
        <h1>TechCorp Web Application</h1> <br>
        <h2>Designed By Abioye Oluwapelumi Abdul-lateef</h2>

        <div class="status">✓ Server is running successfully!</div>
        
        <div class="info-box">
            <h2 style="margin-top: 0;">Server Information</h2>
            <div class="info-item">
                <span class="label">Instance ID:</span>
                <span class="value">$INSTANCE_ID</span>
            </div>
            <div class="info-item">
                <span class="label">Availability Zone:</span>
                <span class="value">$AVAILABILITY_ZONE</span>
            </div>
            <div class="info-item">
                <span class="label">Private IP:</span>
                <span class="value">$PRIVATE_IP</span>
            </div>
            <div class="info-item">
                <span class="label">Server:</span>
                <span class="value">Apache/Amazon Linux 2</span>
            </div>
        </div>
        
        <div class="footer">
            <p>Deployed via Terraform | High Availability Architecture</p>
            <p>© 2025 TechCorp - Cloud Infrastructure</p>
        </div>
    </div>
</body>
</html>
EOF

systemctl enable httpd
systemctl start httpd

useradd -m techcorpuser
echo "techcorpuser:TechCorp2024!" | chpasswd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
echo "techcorpuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/techcorpuser