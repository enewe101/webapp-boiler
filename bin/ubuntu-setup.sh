# Set environment
# TODO: change this url to point to your new repo
source <(curl https://raw.githubusercontent.com/enewe101/webapp-boiler/master/.env.dev)

# This script sets up the staging environment on an Ubuntu 16 host.
export HOST=$STAGE_HOST

# Enable firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

# Create a non-root user to run the app
echo creating non-root user called $HOST_USER
useradd --create-home $HOST_USER
echo $HOST_USER:$HOST_USER_PASS | chpasswd
usermod -aG sudo $HOST_USER

# Copy some .vimrc into appuser to make development a bit easier
# TODO: change this url to point to your new repo
wget https://raw.githubusercontent.com/enewe101/webapp-boiler/master/config/.vimrc -O /home/$HOST_USER/.vimrc

# Install docker
# Remove any old version
echo installing docker...
apt-get remove docker docker-engine docker.io &> /dev/null
apt-get update > /dev/null
apt-get install -y\
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common > /dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88 | grep fingerprint
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" > /dev/null
apt-get update > /dev/null
apt-get install -y docker-ce

# Make the HOST_USER able to run docker
echo adding $HOST_USER to docker group...
groupadd docker
usermod -aG docker $HOST_USER
systemctl enable docker

# Install docker-compose
echo installing docker-compose
curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose  
chmod +x /usr/local/bin/docker-compose

# Clone the github repo.  Remove remotes from the repo so that you don't
# commit to the boilerplate repo -- you need to make a repo for this project!
# TODO: Make this point to your project's new git repo
git clone https://github.com/enewe101/webapp-boiler.git /home/$HOST_USER/app 
cd /home/$HOST_USER/app
# TODO: This is a precaution to prevent accidentally commiting a new project's
# edits to the webap-boiler repo.  Remove it now that you've set up your own
# repo.
git remote rm origin

# Make a self-signed certificate -- note in production, you need a real
# certificate!  Use bin/letsencrypt.sh to get it.
echo "creating certificate for $HOST"
bin/self-sign-cert.sh

# Give the app folder and everything in it to appuser
chown -R $HOST_USER:$HOST_USER /home/$HOST_USER/app

# Drop into the non-root user
su $HOST_USER

