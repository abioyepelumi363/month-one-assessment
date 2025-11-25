#!/bin/bash
yum update -y
amazon-linux-extras enable postgresql14
yum clean metadata
yum install -y postgresql postgresql-server

postgresql-setup initdb

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf

cat >> /var/lib/pgsql/data/pg_hba.conf <<EOF
host    all             all             10.0.0.0/16             md5
EOF

systemctl enable postgresql
systemctl start postgresql

sleep 10

sudo -u postgres psql <<EOF
CREATE DATABASE techcorp_db;
CREATE USER techcorp_user WITH ENCRYPTED PASSWORD 'TechCorp2024!';
GRANT ALL PRIVILEGES ON DATABASE techcorp_db TO techcorp_user;
EOF

useradd -m techcorpuser
echo "techcorpuser:TechCorp2024!" | chpasswd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
echo "techcorpuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/techcorpuser