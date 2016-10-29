#!/bin/sh

JDK=jdk1.7.0_72
JDK_FILE=jdk-7u72-linux-x64.tar.gz

MYSQL_PASSWORD=admin

SONAR_DB_NAME=sonar
SONAR_DB_USER=sonar
SONAR_DB_PASS=sonar

SONAR_VERSION=4.5.1
SONAR_NAME=sonarqube-$SONAR_VERSION
SONAR_DIR=/opt/$SONAR_NAME
SONAR_ZIP=$SONAR_NAME.zip
SONAR_URL=http://dist.sonar.codehaus.org/$SONAR_ZIP
SONAR_USER=sonar
SONAR_GROUP=sonar

# Install various packages required to run SonarQube
if [ -f /etc/redhat-release ]; then
    yum -y install unzip
else
    apt-get update -y
    apt-get install -y -q unzip
fi

# Install MySQL
if [ -f /etc/redhat-release ]; then
    yum -y install mysql-server
    /sbin/service mysqld start
    /usr/bin/mysqladmin -u root password "$MYSQL_PASSWORD"
else
    echo mysql-server-5.5 mysql-server/root_password password $MYSQL_PASSWORD | debconf-set-selections
    echo mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWORD | debconf-set-selections
    apt-get install -y -q mysql-server
    apt-get clean
fi

# Create database
mysql -u root -p$MYSQL_PASSWORD -e 'show databases;'| grep $SONAR_DB_NAME > /dev/null
if [ "$?" = "1" ]; then
    cat > /tmp/database-setup.sql <<EOF
CREATE DATABASE $SONAR_DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER '$SONAR_DB_USER'@'%' IDENTIFIED BY '$SONAR_DB_PASS';
GRANT ALL ON $SONAR_DB_NAME.* TO '$SONAR_DB_USER'@'%' IDENTIFIED BY '$SONAR_DB_PASS';
GRANT ALL ON $SONAR_DB_NAME.* TO '$SONAR_DB_USER'@'localhost' IDENTIFIED BY '$SONAR_DB_PASS';

DROP USER ''@'localhost';
DROP USER ''@'sonar.localdomain';
FLUSH PRIVILEGES;
EOF
    mysql -u root -p$MYSQL_PASSWORD < /tmp/database-setup.sql
fi

# Install Java
mkdir -p /opt
if [ ! -d /opt/$JDK ]; then
    tar -xzf /vagrant/files/$JDK_FILE -C /opt
fi

# Setup a user to run the SonarQube server
/usr/sbin/groupadd -r $SONAR_GROUP 2>/dev/null
/usr/sbin/useradd -c $SONAR_USER -r -s /bin/bash -d $SONAR_DIR -g $SONAR_GROUP $SONAR_USER 2>/dev/null

# Install SonarQube zip file
if [ ! -d $SONAR_DIR ]; then
    if [ ! -f /vagrant/files/$SONAR_ZIP ]; then
        wget -q --no-proxy $SONAR_URL -P /vagrant/files
    fi
    unzip -q /vagrant/files/$SONAR_ZIP -d /opt
fi

chown -R $SONAR_USER:$SONAR_GROUP $SONAR_DIR

# Configure SonarQube to use MySQL
sed -i -e "s/^#\(sonar.jdbc.username=\).*/\1$SONAR_DB_NAME/" \
       -e "s/^#\(sonar.jdbc.password=\).*/\1$SONAR_DB_PASS/" \
       -e "s/^#\(sonar.jdbc.url=jdbc:mysql:.*\)/\1/" $SONAR_DIR/conf/sonar.properties

# Configure SonarQube to use Java 7
sed -i -e "s/^\(wrapper.java.command=\).*/\1\/opt\/$JDK\/bin\/java/" $SONAR_DIR/conf/wrapper.conf

if [ -f /etc/redhat-release ]; then
    # Allow connections
    iptables -I INPUT 5 -p tcp --dport 9000 -j ACCEPT
    iptables --line-numbers -L INPUT -n
    /sbin/service iptables save
fi

# Install init script to start SonarQube on server boot
ln -s $SONAR_DIR/bin/linux-x86-64/sonar.sh /usr/bin/sonar
if [ -f /etc/redhat-release ]; then
    if [ ! -f /etc/rc.d/init.d/sonar ]; then
        cp /vagrant/scripts/sonar /etc/init.d/sonar
        chmod 755 /etc/init.d/sonar
        sudo chkconfig --add sonar
    fi
    /sbin/service sonar start
else
    if [ ! -f /etc/init.d/sonar ]; then
        cp /vagrant/scripts/sonar /etc/init.d/sonar
        chmod 755 /etc/init.d/sonar
        update-rc.d sonar defaults
    fi
    /etc/init.d/sonar start
fi
