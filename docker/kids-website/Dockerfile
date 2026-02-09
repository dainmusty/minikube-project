# Use a lightweight web server image
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy website files
COPY index.html /usr/share/nginx/html/index.html
COPY playground.jpg /usr/share/nginx/html/playground.jpg

# Change Nginx config to listen on 8080
RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf

# Expose the correct port
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
