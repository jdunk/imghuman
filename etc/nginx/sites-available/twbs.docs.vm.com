server {
    listen 80;
    listen [::]:80;

    server_name twbs.docs.vm.com bs.docs.vm.com bootstrap.docs.vm.com twbs.docs.vm.jdunk.co bs.docs.vm.jdunk.co bootstrap.docs.vm.jdunk.co twbs.vm.jdunk.co bs.vm.jdunk.co bootstrap.vm.jdunk.co;

    access_log /var/log/nginx/twbs.docs.vm.com.access.log;
    error_log /var/log/nginx/twbs.docs.vm.com.error.log;

    root /var/www/twbs.docs.vm.com;

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