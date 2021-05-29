FROM alpine
CMD while true; do echo -e "HTTP/1.1 200 OK\n\n :)" | nc -l -p 80; done
EXPOSE 80
