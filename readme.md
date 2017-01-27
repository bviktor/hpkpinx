# About

**HPKPinx** allows for automated, regularly renewed [HPKP](https://en.wikipedia.org/wiki/HTTP_Public_Key_Pinning) configuration using the following components:

* [Nginx](http://nginx.org/)
* [Let's Encrypt](https://letsencrypt.org/) via the [dehydrated](https://github.com/lukas2511/dehydrated) client

The script has been tested and deployed successfully on CentOS 7 machines.
Testing involved disaster recovery using the static backup pin, which is generated automatically upon install.

# Installation

First off, you need to have private key rollover enabled, otherwise **you may render your site inaccessible**. Add to `/opt/dehydrated/config`:

~~~
PRIVATE_KEY_ROLLOVER="yes"
~~~

Then request a certificate renewal which generates new production and rollover private keys.
Verify that you indeed have `privkey.pem` and `privkey.roll.pem` under `dehydrated/certs/<hostname>`.

dehydrated certs should be available under `/etc/nginx/certs`:

~~~
ln -sT /opt/dehydrated/certs /etc/nginx/certs
~~~

Now get a fresh copy of HPKPinx:

~~~
git clone https://github.com/bviktor/hpkpinx.git /opt/hpkpinx
cd /opt/hpkpinx
./install.sh
~~~

After this, you're prompted to **move your backup private key off-server**, which you should most definitely do right away.

Also make sure to regenerate the pins upon each renewal by calling `hpkpinx.sh`.
For example, if you're using the [Certzure](https://github.com/bviktor/certzure) DNS-01 hook, add to the end of `/opt/certzure/certzure.sh`:

~~~
/opt/hpkpinx/hpkpinx.sh $1 $2
~~~

Naturally, you also have to restart Nginx after each renewal, but that is already implied by using Let's Encrypt.


Then add to your Nginx host config:

~~~
include hpkp.conf;
~~~

# Configuration

The config file is located at `/opt/hpkpinx/config.sh`. You have the following options:

### CERT_ROOT

The path to the folder where dehydrated is putting the Certs (eg. $CERTDIR from the dehydrated config).
This is Optional, defaults to certs in the nginx folder.

### HPKP_AGE

The time, in seconds, that the browser should remember that this site is only to be accessed using one of the defined keys.

### STATIC_PIN

This is the pin of your backup key. Normally you shouldn't need to change this, unless you want to replace the generated backup key with your own.
In this case, you can generate a pin for your private key with:

~~~
hpkpinx.sh generate_pin <your_key.pem>
~~~

### DEPLOY_HPKP

* If set to `0` (the default), Nginx will only send the `Public-Key-Pins-Report-Only` header and HPKP is not applied.
* If set to `1`, Nginx sends the `Public-Key-Pins` header and the HPKP policy for your site goes live in
[supported browsers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Public_Key_Pinning#Browser_compatibility).

# Resources

* [HPKP: HTTP Public Key Pinning](https://scotthelme.co.uk/hpkp-http-public-key-pinning/) by Scott Helme
* [HPKP Analyser](https://report-uri.io/home/pkp_analyse) by Scott Helme
* [SecurityHeaders.io](https://securityheaders.io/) by Scott Helme
* [HPKP Reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Public_Key_Pinning) by Mozilla
* [HTTP Public-Key-Pinning Explained](https://timtaubert.de/blog/2014/10/http-public-key-pinning-explained/) by Tim Taubert
* [Getting started with Let's Encrypt!](https://scotthelme.co.uk/setting-up-le/) by Scott Helme
