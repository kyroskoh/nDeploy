#!/bin/bash
#Author: Anoop P Alias

##Vars
NGINX_VERSION="1.8.0"
NGINX_RPM_ITER="6.el7"
NPS_VERSION="1.9.32.6"
MY_RUBY_VERSION="2.2.3"
PASSENGER_VERSION="5.0.20"
CACHE_PURGE_VERSION="2.3"
NAXSI_VERSION="0.54"

rsync -av --exclude 'etc/rc.d' nginx-pkg-64-common/ nginx-pkg-64-centos7/

yum install rpm-build libcurl-devel pcre-devel

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | sudo bash -s stable --ruby=${MY_RUBY_VERSION}
. /usr/local/rvm/scripts/rvm
rvm use ruby-${MY_RUBY_VERSION}
echo ${MY_RUBY_VERSION}
/usr/local/rvm/rubies/ruby-${MY_RUBY_VERSION}/bin/gem install passenger -v ${PASSENGER_VERSION}
/usr/local/rvm/rubies/ruby-${MY_RUBY_VERSION}/bin/gem install fpm

wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xvzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}/

wget https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}.tar.gz
tar -xvzf ${NAXSI_VERSION}.tar.gz


wget http://labs.frickle.com/files/ngx_cache_purge-${CACHE_PURGE_VERSION}.tar.gz
tar -xvzf ngx_cache_purge-${CACHE_PURGE_VERSION}.tar.gz

wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip
unzip release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-release-${NPS_VERSION}-beta/
wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
tar -xzvf ${NPS_VERSION}.tar.gz
cd ..

./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --add-module=naxsi-${NAXSI_VERSION}/naxsi_src --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-file-aio --with-ipv6 --with-http_spdy_module --add-module=ngx_pagespeed-release-${NPS_VERSION}-beta --add-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-module=ngx_cache_purge-${CACHE_PURGE_VERSION} --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'
make DESTDIR=./tempo install

rsync -av naxsi-${NAXSI_VERSION}/naxsi_config/naxsi_core.rules ../nginx-pkg-64-centos7/etc/nginx/conf.d/naxsi_core.rules
rm -rf ../nginx-pkg-64-centos7/usr/nginx/nxapi
rsync -av naxsi-${NAXSI_VERSION}/nxapi ../nginx-pkg-64-centos7/usr/nginx/

sed -i "s/RUBY_VERSION/$MY_RUBY_VERSION/g" ../nginx-pkg-64-centos7/etc/nginx/conf.d/passenger.conf
sed -i "s/PASSENGER_VERSION/$PASSENGER_VERSION/g" ../nginx-pkg-64-centos7/etc/nginx/conf.d/passenger.conf
sed -i "s/RUBY_VERSION/$MY_RUBY_VERSION/g" ../nginx-pkg-64-centos7/usr/nginx/scripts/nginx-passenger-setup.sh
sed -i "s/PASSENGER_VERSION/$PASSENGER_VERSION/g" ../nginx-pkg-64-centos7/usr/nginx/scripts/nginx-passenger-setup.sh

rm -f ../nginx-pkg-64-centos7/usr/sbin/nginx
cp -p ./tempo/usr/sbin/nginx ../nginx-pkg-64-centos7/usr/sbin/nginx
rm -rf ../nginx-pkg-64-centos7/usr/nginx/buildout
cp -pvr /usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/buildout ../nginx-pkg-64-centos7/usr/nginx/buildout
cd ../nginx-pkg-64-centos7
fpm -s dir -t rpm -C ../nginx-pkg-64-centos7 --vendor "PiServe Technologies" --version ${NGINX_VERSION} --iteration ${NGINX_RPM_ITER} -a $(arch) -m info@piserve.com -e --description "nDeploy custom nginx package" --url http://piserve.com --conflicts nginx -d zlib -d openssl -d pcre -d libcurl --after-install ../after_nginx_install --name nginx-nDeploy .