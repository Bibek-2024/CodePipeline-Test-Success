FROM nginx:alpine

# Change Nginx default port from 80 to 3000
RUN sed -i 's/listen\(.*\)80;/listen 3000;/' /etc/nginx/conf.d/default.conf

# Create a custom landing page
RUN echo "<h1>Deployment Success!</h1><p>Running on Port 3000 (Internal) and Port 80 (External)</p>" > /usr/share/nginx/html/index.html

# Expose the internal port
EXPOSE 3000
