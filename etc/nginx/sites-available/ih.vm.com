server {
    listen 80;
    listen [::]:80;

    server_name ih.vm.com *.ih.vm.com;

    rewrite ^ https://$server_name$request_uri? permanent;
}

server {
	listen 443;
    server_name ih.vm.com *.ih.vm.com;
    
    ssl on;
    ssl_certificate /etc/nginx/ssl/vm.com.pem;
    ssl_certificate_key /etc/nginx/ssl/vm.com.key;
    
    ssl_session_timeout 5m;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
    ssl_prefer_server_ciphers on;
    
	access_log /var/log/nginx/ih.vm.com.access.log;
	error_log /var/log/nginx/ih.vm.com.error.log debug;

    root /var/www/ih.vm.com/public;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        if (!-f $document_root$fastcgi_script_name) {
            #more_set_headers "X-jared-dr: $document_root";
            #more_set_headers "X-jared-fsn: $fastcgi_script_name";
            return 404;
        }

        # "cgi.fix_pathinfo = 0;" in php.ini is recommended to avoid /upload/some.gif/index.php exploit
        # but this exploit is not possible here because we are checking that the php file exists

        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }

	# deny access to .ht* files

	location ~ /\.ht {
		deny all;
	}
}
