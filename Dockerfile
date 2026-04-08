FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY tasks.html /usr/share/nginx/html/tasks.html
EXPOSE 10000
CMD ["nginx", "-g", "daemon off;"]
