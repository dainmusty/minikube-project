# Use a lightweight web server image
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy website files to nginx public folder
COPY index.html /usr/share/nginx/html/index.html
COPY playground.jpg /usr/share/nginx/html/playground.jpg

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
