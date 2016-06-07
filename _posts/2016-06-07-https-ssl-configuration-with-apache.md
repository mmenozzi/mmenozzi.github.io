---
layout:   post
title:    "HTTPS/SSL Configuration with Apache"
date:     2016-06-07 00:00:00
author:   "Manuele Menozzi"
tags:     [apache, ssl, devops]
---

Recently I had to configure several Apache virtual hosts to enable SSL. It may seems a trivial task but I discovered that is not as easy as it seems if you want to obtain good maintainability and security. Here follows my hints assuming that the Apache version is 2.4.

Avoid to duplicate directives
-----------------------------

As you may know, to have SSL support on your existing site you have to enable the Apache's SSL mod and then enable a virutal host on port 443. For example:

	<VirtualHost *:80>
        # Here the site's specific directives like DocuentRoot, ServerName, etc..
	</VirtualHost>

	<IfModule mod_ssl.c>
        <VirtualHost *:443>
            SSLEngine on
            SSLCertificateFile /path/to/ssl/certificate.crt
            SSLCertificateKeyFile /path/to/ssl/key.key
            SSLCertificateChainFile /path/to/ssl/intermediate/certificate.crt

            # Here the same directives of the HTTP virtual host
        </VirtualHost>
	</IfModule>
	
As you can see, most of the times you have to repeat site's specific directives in both HTTP and HTTPS virtual hosts. As a developer I know very well that every duplication is a point of potential mistakes.

So, to avoid this duplication I used the `Include` directive. For example:

	<VirtualHost *:80>
        Include /path/to/site/configuration.conf
	</VirtualHost>

	<IfModule mod_ssl.c>
        <VirtualHost *:443>
            SSLEngine on
            SSLCertificateFile /path/to/ssl/certificate.crt
            SSLCertificateKeyFile /path/to/ssl/key.key
            SSLCertificateChainFile /path/to/ssl/intermediate/certificate.crt

            Include /path/to/site/configuration.conf
        </VirtualHost>
	</IfModule>
	
Avoid POODLE (SSLv3) attacks
----------------------------

[POODLE (SSLv3)](https://blog.qualys.com/ssllabs/2014/10/15/ssl-3-is-dead-killed-by-the-poodle-attack) is a kind of attack which exploits a vulnerability in the SSLv3 protocol. So for a better security you have to disable it.

	SSLProtocol all -SSLv3
	
Mitigate BEAST attacks and disable RC4 cihpers
----------------------------------------------

Again, for security reasons, I used to set a specific ciphers list which is recommendet to mitigate BEAST attacks. This list also disable RC4 chipers which are considered unsecure. To do this I used the following directives:

	SSLHonorCipherOrder on
	SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4	 

Test certificate installation
-----------------------------

I suggest you to use the following tool to test your certificate installation: [https://www.ssllabs.com/ssltest/analyze.html](https://www.ssllabs.com/ssltest/analyze.html). It tests your SSL configuration against several vulnerabilities and with several browser.

With the hints described above I get a grade A!
