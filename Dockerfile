FROM nginx:alpine
RUN echo "<h1>Hello from my free automated Pipeline!</h1>" > /usr/share/nginx/html/index.html
EXPOSE 80
